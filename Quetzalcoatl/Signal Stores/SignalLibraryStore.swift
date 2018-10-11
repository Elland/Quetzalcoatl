//
//  SignalLibraryStore.swift
//  Quetzalcoatl
//
//  Created by Igor Ranieri on 19.04.18.
//

public protocol SignalLibraryStoreDelegate: class {
    func storeSignalLibraryValue(_ value: Data, key: String, type: SignalLibraryStore.LibraryStoreType)

    func deleteSignalLibraryValue(key: String, type: SignalLibraryStore.LibraryStoreType) -> Bool

    func retrieveSignalLibraryValue(key: String, type: SignalLibraryStore.LibraryStoreType) -> Data?

    func retrieveAllSignalLibraryValue(ofType type: SignalLibraryStore.LibraryStoreType) -> [Data]
}

public class SignalLibraryStore: NSObject, SignalLibraryStoreProtocol {
    private let IdentityKeyStoreIdentityKey = "IdentityKeyStoreIdentityKey"
    private let LocalRegistrationIdKey = "LocalRegistrationIdKey"

    public var delegate: SignalLibraryStoreDelegate

    public var context: SignalContext!

    public enum LibraryStoreType: String {
        case session
        case preKey
        case signedPreKey
        case identityKey
        case senderKey
        case currentSignedPreKey
        case localRegistrationId
    }

    struct SignalLibrarySessionRecord: Codable, Hashable {
        var key: String
        var deviceId: Int32
        var data: Data
    }

    struct SignalLibraryPreKeyRecord: Codable, Hashable {
        var key: UInt32
        var data: Data
    }

    struct SignalLibraryIdentityKeyRecord: Codable, Hashable {
        var key: String
        var data: Data
    }

    struct SignalLibrarySenderKeyRecord: Codable, Hashable {
        var key: String
        var data: Data
    }

    @objc public var identityKeyPair: SignalIdentityKeyPair? {
        guard let identityKeyData = self.delegate.retrieveSignalLibraryValue(key: IdentityKeyStoreIdentityKey, type: .identityKey),
            let identityKey = try? self.decoder.decode(SignalLibraryIdentityKeyRecord.self, from: identityKeyData),
            let data = identityKey.data as NSData?
            else { return nil }

        var key_pair: UnsafeMutablePointer<ratchet_identity_key_pair>?
        ratchet_identity_key_pair_deserialize(&key_pair, data.bytes.assumingMemoryBound(to: UInt8.self), data.length, self.context.context)

        return SignalIdentityKeyPair(identityKeyPair: key_pair!)
    }

    @objc public var localRegistrationId: UInt32 {
        set {
            let value = NSNumber(value: newValue)
            let data = NSKeyedArchiver.archivedData(withRootObject: value)
            self.delegate.storeSignalLibraryValue(data, key: LocalRegistrationIdKey, type: .localRegistrationId)
        }
        get {
            guard let data = self.delegate.retrieveSignalLibraryValue(key: LocalRegistrationIdKey, type: .localRegistrationId),
                let value = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSNumber else {
                return 0
            }

            return value.uint32Value
        }
    }

    private var currentlySignedPreKeyId: UInt32 {
        didSet {
            let value = NSNumber(value: self.currentlySignedPreKeyId)
            let data = NSKeyedArchiver.archivedData(withRootObject: value)
            self.delegate.storeSignalLibraryValue(data, key: LibraryStoreType.currentSignedPreKey.rawValue, type: .currentSignedPreKey)
        }
    }

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(delegate: SignalLibraryStoreDelegate) {
        self.delegate = delegate

        // restore currently signed prekey data from db.
        if let currentlySignedPreKeyData = self.delegate.retrieveSignalLibraryValue(key: LibraryStoreType.currentSignedPreKey.rawValue, type: .currentSignedPreKey) {

            let number = NSKeyedUnarchiver.unarchiveObject(with: currentlySignedPreKeyData) as? NSNumber
            self.currentlySignedPreKeyId = number?.uint32Value ?? .max
        } else {
            self.currentlySignedPreKeyId = .max
        }

        super.init()
    }

    private func key(for address: SignalAddress, groupId: String) -> String {
        return "\(address.name)\(address.deviceId)\(groupId)"
    }

    private func keyForPreKey(id: UInt32) -> String {
        return "prekey: \(id)"
    }
    private func keyForSignedPreKey(id: UInt32) -> String {
        return "signedprekey: \(id)"
    }

    private let currentlySignedPreKeyStoreKey = UInt32.max

    // MARK: SignalSessionStore
    @objc public func deviceSessionRecord(for addressName: String, deviceId: Int32) -> Data? {
        let address = SignalAddress(name: addressName, deviceId: deviceId)

        guard let sessionData = self.delegate.retrieveSignalLibraryValue(key: address.nameForStoring, type: .session),
            let sessionRecord = try? self.decoder.decode(SignalLibrarySessionRecord.self, from: sessionData)
            else { return nil }

        return sessionRecord.data
    }

    /**
     * Returns a copy of the serialized session record corresponding to the
     * provided recipient ID + device ID tuple.
     * or nil if not found.
     */
    @objc public func sessionRecord(for address: SignalAddress) -> Data {
        guard let deviceSessionData = self.deviceSessionRecord(for: address.name, deviceId: address.deviceId) else {
                var record: UnsafeMutablePointer<session_record>?
                var state: UnsafeMutablePointer<session_state>?
                session_state_create(&state, self.context.context)
                session_record_create(&record, state, self.context.context)

                var buffer: UnsafeMutablePointer<signal_buffer>?
                session_record_serialize(&buffer, record)
                let data = Data(bytes: signal_buffer_data(buffer), count: signal_buffer_len(buffer))

                signal_buffer_free(buffer)

                return data
        }

        return deviceSessionData
    }

    /**
     * Commit to storage the session record for a given
     * recipient ID + device ID tuple.
     *
     * Return YES on success, NO on failure.
     */
    @objc public func storeSessionRecord(_ recordData: Data, for address: SignalAddress) -> Bool {
        let newSessionRecord = SignalLibrarySessionRecord(key: address.name, deviceId: address.deviceId, data: recordData)

        let sessionData = try! self.encoder.encode(newSessionRecord)
        _ = self.delegate.deleteSignalLibraryValue(key: address.nameForStoring, type: .session)
        self.delegate.storeSignalLibraryValue(sessionData, key: address.nameForStoring, type: .session)

        return self.sessionRecordExists(for: address)
    }

    /**
     * Determine whether there is a committed session record for a
     * recipient ID + device ID tuple.
     */
    @objc public func sessionRecordExists(for address: SignalAddress) -> Bool {
        let record = self.sessionRecord(for: address)

        let sessionRecord = SessionRecord(data: record, signalContext: self.context)

        let hasSenderChain = sessionRecord.sessionRecordPointer.pointee.state.pointee.has_sender_chain == 1

        return hasSenderChain
    }

    /**
     * Remove a session record for a recipient ID + device ID tuple.
     */
    @objc public func deleteSessionRecord(for address: SignalAddress) -> Bool {
        return self.delegate.deleteSignalLibraryValue(key: address.nameForStoring, type: .session)
    }

    /**
     * Remove the session records corresponding to all devices of a recipient ID.
     *
     * @return the number of deleted sessions on success, negative on failure
     */
    @objc public func deleteAllDeviceSessions(for addressName: String) -> Int32 {
        var key = SignalAddress(name: addressName, deviceId: 0)
        var count: Int32 = 0

        while self.delegate.retrieveSignalLibraryValue(key: key.nameForStoring, type: .session) != nil {
            if self.delegate.deleteSignalLibraryValue(key: key.nameForStoring, type: .session) {

                count += 1
                key = SignalAddress(name: addressName, deviceId: count)
            }
        }

        return count
    }

    // MARK: SignalPreKeyStore
    /**
     * Load a local serialized PreKey record.
     * return nil if not found
     */
    @objc public func loadPreKey(with id: UInt32) -> Data? {
        guard let preKeyData = self.delegate.retrieveSignalLibraryValue(key: self.keyForPreKey(id: id), type: .preKey),
            let preKey = try? self.decoder.decode(SignalLibraryPreKeyRecord.self, from: preKeyData)
            else { return nil }

        return preKey.data
    }

    /**
     * Store a local serialized PreKey record.
     * return YES if storage successful, else NO
     */
    @discardableResult @objc public func storePreKey(data: Data, id: UInt32) -> Bool {
        let prekeyData = try! self.encoder.encode(SignalLibraryPreKeyRecord(key: id, data: data))
        self.delegate.storeSignalLibraryValue(prekeyData, key: self.keyForPreKey(id: id), type: .preKey)

        return true
    }

    /**
     * Determine whether there is a committed PreKey record matching the
     * provided ID.
     */
    @objc public func containsPreKey(with id: UInt32) -> Bool {
        return self.delegate.retrieveSignalLibraryValue(key: self.keyForPreKey(id: id), type: .preKey) != nil
    }

    /**
     * Delete a PreKey record from local storage.
     */
    @discardableResult
    @objc public func deletePreKey(with id: UInt32) -> Bool {
        return self.delegate.deleteSignalLibraryValue(key: self.keyForPreKey(id: id), type: .preKey)
    }

    public func nextPreKeyId() -> UInt32 {
        let prekeysData = self.delegate.retrieveAllSignalLibraryValue(ofType: .preKey)
        var keys: [UInt32] = []

        for prekeyData in prekeysData {
            let preKeyRecord = try! decoder.decode(SignalLibraryPreKeyRecord.self, from: prekeyData)
            keys.append(preKeyRecord.key)
        }

        guard let lastKey = keys.sorted().last else { return 1 }

        return lastKey + 1
    }

    // MARK: SignalSignedPreKeyStore
    /**
     * Load a local serialized signed PreKey record.
     */
    @objc public func loadSignedPreKey(with id: UInt32) -> Data? {
        guard let signedPreKeyData = self.delegate.retrieveSignalLibraryValue(key: self.keyForSignedPreKey(id: id), type: .signedPreKey),
            let signedPreKey = try? self.decoder.decode(SignalLibraryPreKeyRecord.self, from: signedPreKeyData)
            else { return nil }

        return signedPreKey.data
    }

    /**
     * Store a local serialized signed PreKey record.
     */
    @discardableResult
    @objc public func storeSignedPreKey(_ signedPreKey: Data?, signedPreKeyId: UInt32) -> Bool {
        if let signedPreKey = signedPreKey {
            let signedPrekeyData = try! self.encoder.encode(SignalLibraryPreKeyRecord(key: signedPreKeyId, data: signedPreKey))
            self.delegate.storeSignalLibraryValue(signedPrekeyData, key: self.keyForSignedPreKey(id: signedPreKeyId), type: .signedPreKey)
        } else {
            self.removeSignedPreKey(with: signedPreKeyId)
        }

        return self.containsSignedPreKey(with: signedPreKeyId)
    }

    /**
     * Determine whether there is a committed signed PreKey record matching
     * the provided ID.
     */
    @objc public func containsSignedPreKey(with id: UInt32) -> Bool {
        return self.delegate.retrieveSignalLibraryValue(key: self.keyForSignedPreKey(id: id), type: .signedPreKey) != nil
    }

    /**
     * Delete a SignedPreKeyRecord from local storage.
     */
    @discardableResult
    @objc public func removeSignedPreKey(with id: UInt32) -> Bool {
        return self.delegate.deleteSignalLibraryValue(key: self.keyForSignedPreKey(id: id), type: .signedPreKey)
    }

    public func retrieveCurrentSignedPreKeyId() -> UInt32 {
        return self.currentlySignedPreKeyId
    }

    public func storeCurrentSignedPreKeyId(_ id: UInt32) -> Bool {
        self.currentlySignedPreKeyId = id

        return self.currentlySignedPreKeyId != .max
    }

    /**
     * Save a remote client's identity key
     * <p>
     * Store a remote client's identity key as trusted.
     * The value of key_data may be null. In this case remove the key data
     * from the identity store, but retain any metadata that may be kept
     * alongside it.
     */
    public func saveRemoteIdentity(with address: SignalAddress, identityKey: Data?) -> Bool {
        if let identityKey = identityKey {
            let identityKeyRecord = SignalLibraryIdentityKeyRecord(key: address.name, data: identityKey)
            let identityKeyRecordData = try! self.encoder.encode(identityKeyRecord)
            self.delegate.storeSignalLibraryValue(identityKeyRecordData, key: address.nameForStoring, type: .identityKey)

            return self.delegate.retrieveSignalLibraryValue(key: address.nameForStoring, type: .identityKey) != nil
        } else {
            return self.delegate.deleteSignalLibraryValue(key: address.nameForStoring, type: .identityKey)
        }
    }

    public func saveIdentity(_ identityKey: Data?) -> Bool {
        if let identityKey = identityKey {
            let identityKeyRecord = SignalLibraryIdentityKeyRecord(key: self.IdentityKeyStoreIdentityKey, data: identityKey)
            let identityKeyRecordData = try! self.encoder.encode(identityKeyRecord)
            self.delegate.storeSignalLibraryValue(identityKeyRecordData, key: self.IdentityKeyStoreIdentityKey, type: .identityKey)

            return self.delegate.retrieveSignalLibraryValue(key: self.IdentityKeyStoreIdentityKey, type: .identityKey) != nil
        } else {
            return self.delegate.deleteSignalLibraryValue(key: self.IdentityKeyStoreIdentityKey, type: .identityKey)
        }
    }

    /**
     * Verify a remote client's identity key.
     *
     * Determine whether a remote client's identity is trusted.  Convention is
     * that the TextSecure protocol is 'trust on first use.'  This means that
     * an identity key is considered 'trusted' if there is no entry for the recipient
     * in the local store, or if it matches the saved key for a recipient in the local
     * store.  Only if it mismatches an entry in the local store is it considered
     * 'untrusted.'
     */
    @objc public func isTrustedIdentity(with address: SignalAddress, identityKey: Data) -> Bool {
        guard let existingKeyData = self.delegate.retrieveSignalLibraryValue(key: address.nameForStoring, type: .identityKey),
            let existingKey = try? self.decoder.decode(SignalLibraryIdentityKeyRecord.self, from: existingKeyData)
            else { return true }

        if existingKey.data == identityKey {
            return true
        }

        return false
    }

    // MARK: SignalSenderKeyStore

    /**
     * Store a serialized sender key record for a given
     * (groupId + senderId + deviceId) tuple.
     */
    @objc public func storeSenderKey(with data: Data, signalAddress: SignalAddress, groupId: String) -> Bool {
        let key = self.key(for: signalAddress, groupId: groupId)
        self.delegate.storeSignalLibraryValue(data, key: key, type: .senderKey)

        return true
    }

    /**
     * Returns a copy of the sender key record corresponding to the
     * (groupId + senderId + deviceId) tuple.
     */
    @objc public func loadSenderKey(for address: SignalAddress, groupId: String) -> Data? {
        let key = self.key(for: address, groupId: groupId)
        return self.delegate.retrieveSignalLibraryValue(key: key, type: .senderKey)
    }

    @objc public func allDeviceIds(for addressName: String) -> [Int32] {
        let sessions = self.delegate.retrieveAllSignalLibraryValue(ofType: .session).map({ try! self.decoder.decode(SignalLibrarySessionRecord.self, from: $0) }).filter({$0.key == addressName})

        if !sessions.isEmpty {
            return sessions.map({ r in r.deviceId })
        }

        return []
    }
}
