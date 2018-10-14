//
//  Quetzalcoatl
//  Quetzalcoatl
//
//  Created by Igor Ranieri on 06.04.18.
//

import Starscream

public struct DebugLevel {
    public enum DebugLevelType {
        case errorOnly
        case verbose
    }

    public static var current: DebugLevelType = .errorOnly
}

extension Array where Element: Equatable {
    mutating func delete(element elementToDelete: Element) {
        self = self.filter { element -> Bool in
            element != elementToDelete
        }
    }

    func deleting(element elementToDelete: Element) -> [Element] {
        return self.filter { element -> Bool in
            element != elementToDelete
        }
    }
}

public protocol SignalSocketConnectionStatusDelegate: class {
    func socketConnectionStatusDidChange(_ isConnected: Bool)
}

public class Quetzalcoatl {
    var socket: WebSocket?

    public var messageManager: SignalMessageManager?

    /// TODO: make this internal, move user bootstrapping data generation to client?
    public var libraryStore: SignalLibraryStoreProtocol
    public var signalContext: SignalContext

    var libraryStoreBridge: SignalLibraryStoreBridge

    public weak var connectionStatusDelegate: SignalSocketConnectionStatusDelegate?

    public var store: SignalServiceStore

    public var shouldKeepSocketAlive: Bool = false

    public var isSocketConnected: Bool = false {
        didSet {
            self.connectionStatusDelegate?.socketConnectionStatusDidChange(self.isSocketConnected)
        }
    }

    lazy var keepAliveTimer: Timer = {
        Timer(fire: Date(), interval: 30.0, repeats: true) { _ in
            if self.shouldKeepSocketAlive && self.socket?.isConnected != true {
                self.socket?.connect()
            } else {
                self.socket?.write(ping: Data())
            }
        }
    }()

    public var baseURL: URL

    public init(baseURL: URL, recipientsDelegate: SignalRecipientsDisplayDelegate, persistenceStore: PersistenceStore) {
        self.baseURL = baseURL

        self.libraryStore = SignalLibraryStore(delegate: persistenceStore)
        self.libraryStoreBridge = SignalLibraryStoreBridge(signalStore: self.libraryStore)
        self.signalContext = SignalContext(store: self.libraryStoreBridge)

        self.libraryStore.context = self.signalContext
        self.libraryStoreBridge.setup(with: self.signalContext.context)

        self.store = SignalServiceStore(persistenceStore: persistenceStore, contactsDelegate: recipientsDelegate)
    }

    /// Generates the json dictionary necessary to register a user with the chat service. It saves all the generated data as well.
    /// - Caution:
    ///   **Calling this method again overwrites the locally stored user data!**
    ///
    /// - Parameters:
    ///   - username: the server-side identifier for a user (phone number, UUID, etc).
    ///   - password: a random string.
    /// - Returns: A dictionary mapping the user data needed to register with the chat service.
    public func generateUserBootstrap(username: String, password: String) -> [String: Any] {
        let identityKeyPair = self.signalContext.signalKeyHelper.generateAndStoreIdentityKeyPair()!
        let signalingKey = Data.generateSecureRandomData(count: 52).base64EncodedString()
        let registrationId = signalContext.signalKeyHelper.generateRegistrationId()

        let identityPublicKey = identityKeyPair.publicKey.base64EncodedString()

        let signedPreKey = self.signalContext.signalKeyHelper.generateSignedPreKey(withIdentity: identityKeyPair, signedPreKeyId: 0)
        let preKeys = self.signalContext.signalKeyHelper.generatePreKeys(withStartingPreKeyId: 1, count: 100)

        for prekey in preKeys {
            _ = self.libraryStore.storePreKey(data: prekey.serializedData, id: prekey.preKeyId)
        }

        self.libraryStore.storeSignedPreKey(signedPreKey.serializedData, signedPreKeyId: signedPreKey.preKeyId)
        self.libraryStore.storeCurrentSignedPreKeyId(signedPreKey.preKeyId)
        self.libraryStore.localRegistrationId = registrationId

        let sender = SignalSender(username: username, password: password, deviceId: 1, remoteRegistrationId: registrationId, signalingKey: signalingKey)
        self.store.storeSender(sender)
        
        let networkClient = NetworkClient(baseURL: self.baseURL, username: sender.username, password: sender.password)
        self.messageManager = SignalMessageManager(sender: sender, networkClient: networkClient, signalContext: self.signalContext, store: self.store, delegate: self)

        var prekeysDict = [[String: Any]]()

        for prekey in preKeys {
            let prekeyParam: [String: Any] = [
                "keyId": prekey.preKeyId,
                "publicKey": prekey.keyPair.publicKey.base64EncodedString()
            ]
            prekeysDict.append(prekeyParam)
        }

        let signedPreKeyDict: [String: Any] = [
            "keyId": Int(signedPreKey.preKeyId),
            "publicKey": signedPreKey.keyPair.publicKey.base64EncodedString(),
            "signature": signedPreKey.signature.base64EncodedString()
        ]

        let payload: [String: Any] = [
            "identityKey": identityPublicKey,
            "password": password,
            "preKeys": prekeysDict,
            "registrationId": Int(registrationId),
            "signalingKey": signalingKey,
            "signedPreKey": signedPreKeyDict
        ]

        return payload
    }

    public func startSocket() {
        guard let sender = self.store.fetchSender() else { return }

        let socketURL = URL(string: "wss://\(self.baseURL.host!)/v1/websocket/?login=\(sender.username)&password=\(sender.password)")!

        self.socket = WebSocket(url: socketURL)
        self.socket?.delegate = self
        self.socket?.pongDelegate = self

        self.socket?.connect()

        let networkClient = NetworkClient(baseURL: self.baseURL, username: sender.username, password: sender.password)
        self.messageManager = SignalMessageManager(sender: sender, networkClient: networkClient, signalContext: self.signalContext, store: self.store, delegate: self)

        RunLoop.main.add(self.keepAliveTimer, forMode: .default)
    }

    public func sendGroupMessage(_ body: String = "", message: OutgoingSignalMessage? = nil, type: OutgoingSignalMessage.GroupMetaMessageType, in chat: SignalChat, attachments: [Data] = []) {

        guard let messageSender = self.messageManager else { fatalError() }

        let recipients = chat.recipients.filter({ recipient -> Bool in recipient.name != messageSender.sender.username })

        let message = message ?? OutgoingSignalMessage(recipientId: chat.uniqueId, senderId: messageSender.sender.username, chatId: chat.uniqueId, body: body, groupMessageType: type, store: self.store)
        try? self.store.save(message)

        let dispatchGroup = DispatchGroup()
        for attachment in attachments {
            dispatchGroup.enter()
            self.messageManager?.uploadAttachment(attachment, in: message) { _ in
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            for recipient in recipients {
                self.messageManager?.sendMessage(message, to: recipient, in: chat) { _ in
                    do {
                        try self.store.save(message)
                    } catch (let error) {
                        NSLog("Could not save message: %@", error.localizedDescription)
                    }
                }
            }
        }
    }

    public func sendMessage(_ body: String, to recipient: SignalAddress, in chat: SignalChat, attachments: [Data] = []) {
        guard let senderId = self.messageManager?.sender.username else { fatalError() }
        let message = OutgoingSignalMessage(recipientId: recipient.name, senderId: senderId, chatId: chat.uniqueId, body: body, store: self.store)
        try! self.store.save(message)

        self.dispatchMessage(message, attachments: attachments, to: recipient, in: chat)
    }

    public func retryMessage(_ message: OutgoingSignalMessage, in chat: SignalChat) {
        let attachments = [message.attachment].compactMap({$0})

        for recipient in chat.recipients {
            self.dispatchMessage(message, attachments: attachments, to: recipient, in: chat)
        }
    }

    public func sendInitialGroupMessage(in chat: SignalChat) {
        try? self.store.save(chat)
        self.sendGroupMessage(type: .new, in: chat)
    }

    public func deleteMessage(_ message: SignalMessage) {
        try! self.store.delete(message)
    }

    public func deleteChat(_ chat: SignalChat) {
        try! self.store.delete(chat)
    }

    public func requestNewIdentity(for address: SignalAddress) {
        // TODO: handle multiple devices
        _ = self.libraryStore.saveRemoteIdentity(with: address, identityKey: nil)
    }

    private func dispatchMessage(_ message: OutgoingSignalMessage, attachments: [Data], to recipient: SignalAddress, in chat: SignalChat) {
        let dispatchGroup = DispatchGroup()

        for attachment in attachments {
            dispatchGroup.enter()
            self.messageManager?.uploadAttachment(attachment, in: message) { _ in
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.messageManager?.sendMessage(message, to: recipient, in: chat) { _ in
                do {
                    try self.store.save(message)
                } catch (let error) {
                    NSLog("Could not save message: %@", error.localizedDescription)
                }
            }
        }
    }
}

extension Quetzalcoatl: SignalMessageManagerDelegate {
    func sendSocketMessageAcknowledgement(_ message: Signalservice_WebSocketMessage) {
        self.socket?.write(data: try! message.serializedData())
    }
}

extension Quetzalcoatl: WebSocketDelegate {
    public func websocketDidConnect(socket: WebSocketClient) {
        if DebugLevel.current == .verbose {
            NSLog("did connect")
        }

        self.isSocketConnected = true
    }

    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        self.isSocketConnected = false

        NSLog("did disconnect: \((error as? WSError)?.message ?? "No error")")

        if self.shouldKeepSocketAlive {
            NSLog("reconnecting…")
            self.socket?.connect()
        }
    }

    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        NSLog("received: \(text)")
    }

    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        guard let webSocketMessage = try? Signalservice_WebSocketMessage(serializedData: data) else { return }

        switch webSocketMessage.type {
        case .request:
            self.messageManager?.processSocketMessage(webSocketMessage)
        default:
            fatalError("Should not receive socket response messages")
        }
    }
}

extension Quetzalcoatl: WebSocketPongDelegate {
    public func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
        if DebugLevel.current == .verbose {
            NSLog("pong!")
        }
    }
}
