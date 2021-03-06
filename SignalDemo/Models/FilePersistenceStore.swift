//
//  FilePersistenceStore.swift
//  Demo
//
//  Created by Igor Ranieri on 19.04.18.
//

import Foundation
import Quetzalcoatl
import SQLite

extension SignalServiceAttachmentPointer {
    static func build(from row: Row) throws -> SignalServiceAttachmentPointer {
        let serverIdString = try row.get(SignalAttachmentKeys.serverIdField)

        let keyBlob = try row.get(SignalAttachmentKeys.keyField)
        let digestBlob = try row.get(SignalAttachmentKeys.digestField)
        let dataBlob = try row.get(SignalAttachmentKeys.attachmentDataField)

        let size64 = try row.get(SignalAttachmentKeys.sizeField)
        let stateRaw = try row.get(SignalAttachmentKeys.stateField)

        let contentType: String = try row.get(SignalAttachmentKeys.contentTypeField)
        let uniqueId: String = try row.get(SignalAttachmentKeys.uniqueIdField)


        let serverId = UInt64(serverIdString)!
        let size = UInt32(size64)
        let key = Data.fromDatatypeValue(keyBlob)
        let digest = Data.fromDatatypeValue(digestBlob)
        let data = Data.fromDatatypeValue(dataBlob)
        let state = SignalServiceAttachmentPointer.State(rawValue: Int(stateRaw))!

        var attachment = SignalServiceAttachmentPointer(serverId: serverId, key: key, digest: digest, size: size, contentType: contentType)
        attachment.attachmentData = data
        attachment.uniqueId = uniqueId
        attachment.state = state

        return attachment
    }
}

extension SignalMessage {
    static func build(from row: Row) throws -> SignalMessage {
        guard let kind = SignalMessageKind(rawValue: try row.get(SignalMessageKeys.messageKindField)) else { fatalError("No message kind in db row") }

        let id = try row.get(SignalMessageKeys.uniqueIdField)
        let body = try row.get(SignalMessageKeys.bodyField)
        let chatId = try row.get(SignalMessageKeys.chatIdField)
        let timestamp = try row.get(SignalMessageKeys.timestampField)
        let attachmentIdsString = try row.get(SignalMessageKeys.attachmentIdsField)
        let senderId = try row.get(SignalMessageKeys.senderIdField)

        let message: SignalMessage

        switch kind {
        case .info:
            guard  let messageTypeRaw = try row.get(SignalMessageKeys.messageTypeField)  else { fatalError() }

            let messageType = InfoSignalMessage.MessageType(rawValue: Int(messageTypeRaw))
            let additionalInfo = try row.get(SignalMessageKeys.additionalInfoField)
            let customMessage = try row.get(SignalMessageKeys.customMessageField)

            message = InfoSignalMessage(senderId: senderId ,chatId: chatId, messageType: messageType!, customMessage: customMessage!, additionalInfo: additionalInfo, store: nil)
        case .incoming:
            let isRead = try row.get(SignalMessageKeys.isReadField)
            
            let incoming = IncomingSignalMessage(body: body, senderId: senderId, chatId: chatId, timestamp: UInt64(timestamp)!, store: nil)
            incoming.isRead = isRead!

            message = incoming
        case .outgoing:
            guard let groupMessageTypeRaw = try row.get(SignalMessageKeys.groupMetaMessageTypeField),
                let stateRaw = try row.get(SignalMessageKeys.messageStateField)
                else { fatalError() }

            let messageState = OutgoingSignalMessage.MessageState(rawValue: Int(stateRaw))

            let groupMessageType = OutgoingSignalMessage.GroupMetaMessageType(rawValue: Int(groupMessageTypeRaw))
            let recipientId = try row.get(SignalMessageKeys.recipientIdField)!

            let outgoing = OutgoingSignalMessage(recipientId: recipientId, senderId: senderId, chatId: chatId, body: body, groupMessageType: groupMessageType!, store: nil)
            outgoing.messageState = messageState!

            message = outgoing

        case .error:
            let recipientId = try row.get(SignalMessageKeys.recipientIdField)!
            let errorKindRaw = try row.get(SignalMessageKeys.errorKindField)!
            let kind = ErrorSignalMessage.Kind(rawValue: Int32(errorKindRaw))!

            let error = ErrorSignalMessage(kind: kind, senderId: senderId, recipientId: recipientId, chatId: chatId, store: nil)
            message = error
        }

        message.timestamp = UInt64(timestamp)!
        message.uniqueId = id
        message.attachmentPointerIds = attachmentIdsString.split(separator: ",").map({ s in String(s) })

        return message
    }
}

enum SignalMessageKind: Int64 {
    case incoming, info, outgoing, error

    init(_ message: SignalMessage) {
        if message is ErrorSignalMessage {
            self = .error
        } else if message is InfoSignalMessage {
            self = .info
        } else if message is IncomingSignalMessage {
            self = .incoming
        } else if message is OutgoingSignalMessage {
            self = .outgoing
        } else {
            fatalError()
        }
    }
}

struct SignalAttachmentKeys {
    static let uniqueIdField = Expression<String>("id")

    static let serverIdField = Expression<String>("serverId")
    static let keyField = Expression<Blob>("key")
    static let digestField = Expression<Blob>("digest")
    static let sizeField = Expression<Int64>("size")
    static let contentTypeField = Expression<String>("contentType")
    static let stateField = Expression<Int64>("state")

    static let attachmentDataField = Expression<Blob>("data")
}

struct SignalMessageKeys {
    /* Outgoing messages */
    static let messageStateField = Expression<Int64?>("messageState")
    static let recipientIdField = Expression<String?>("recipientId")
    static let groupMetaMessageTypeField = Expression<Int64?>("groupMetaMessageType")

    /* Incoming messages */
    static let isReadField = Expression<Bool?>("isRead")

    /* Info messages */
    static let messageTypeField = Expression<Int64?>("messageType")
    static let customMessageField = Expression<String?>("customMessage")
    static let additionalInfoField = Expression<String?>("additionalInfo")

    /* Info & Incoming both have a sender */
    static let senderIdField = Expression<String>("senderId")

    /* Error message */
    static let errorKindField = Expression<Int64?>("kind")

    /* Every message */
    static let uniqueIdField = Expression<String>("id")
    static let bodyField = Expression<String>("body")
    static let chatIdField = Expression<String>("chatId")
    static let timestampField = Expression<String>("timestamp")
    static let attachmentIdsField = Expression<String>("attachmentIds") // comma separated, no spaces
    static let messageKindField = Expression<Int64>("_messageKind")
}

struct SignalSenderKeys {
    static let usernameField = Expression<String>("username")
    static let passwordField = Expression<String>("password")
    static let deviceIdField = Expression<Int64>("deviceId")
    static let remoteRegistrationIdField = Expression<Int64>("remoteRegistrationId")
    static let signalingKeyField = Expression<String>("signalingKey")
}

struct SignalRecipientKeys {
    static let nameField = Expression<String>("name")
    static let deviceIdField = Expression<Int64>("deviceId")
}

struct SignalLibraryKeys {
    static let uniqueIdField = Expression<Int64>("id")

    static let identifierField = Expression<String>("uuid")
    static let dataField = Expression<Data>("data")
    static let typeField = Expression<String>("type")
}

struct SignalChatKeys {
    static let uniqueIdField = Expression<String>("id")
    static let recipientIdentifiersField = Expression<String?>("recipientIds") // comma separated, group chat
    static let recipientIdentifierField = Expression<String?>("recipientId") // 1:1 chat
    static let nameField = Expression<String>("name")
    static let currentDraftField = Expression<String>("currentDraft")
    static let isMutedField = Expression<Bool>("isMuted")

    static let lastArchivalDateField = Expression<Double?>("lastArchivalTimestamp")
}

struct UserKeys {
    static let passwordField = Expression<String>("password")
    static let privateKeyField = Expression<String>("privateKey")
    static let usernameField = Expression<String>("username")
    static let nameField = Expression<String?>("name")
    static let avatarField = Expression<String?>("avatar")
    static let descriptionField = Expression<String?>("description")

    // for contacts only
    static let addressField = Expression<String>("address")
}

class FilePersistenceStore {
    let dbConnection: Connection

    let chatsTable = Table("chats")
    let messagesTable = Table("messages")
    let attachmentsTable = Table("attachments")
    let recipientsTable = Table("recipients")
    let senderTable = Table("sender")
    let contactsTable = Table("contacts")
    let userTable = Table("user")
    let signalLibraryTable = Table("signal_library")

    init() {
        let libPath = FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!

        // If this crashes, we've messed up the file path.
        self.dbConnection = try! Connection(libPath.absoluteString.appending("db.sqlite3"))

        // create chats table
        _ = try? self.dbConnection.run(self.chatsTable.create { t in
            t.column(SignalChatKeys.uniqueIdField, primaryKey: true)
            t.column(SignalChatKeys.recipientIdentifiersField)
            t.column(SignalChatKeys.recipientIdentifierField)
            t.column(SignalChatKeys.nameField)
            t.column(SignalChatKeys.currentDraftField)
            t.column(SignalChatKeys.isMutedField)
            t.column(SignalChatKeys.lastArchivalDateField)
        })

        // create messages table
        _ = try? self.dbConnection.run(self.messagesTable.create { t in
            t.column(SignalMessageKeys.uniqueIdField, primaryKey: true)

            t.column(SignalMessageKeys.messageKindField)

            t.column(SignalMessageKeys.bodyField)
            t.column(SignalMessageKeys.chatIdField)
            t.column(SignalMessageKeys.timestampField)

            t.column(SignalMessageKeys.senderIdField)

            t.column(SignalMessageKeys.additionalInfoField)
            t.column(SignalMessageKeys.customMessageField)
            t.column(SignalMessageKeys.messageTypeField)

            t.column(SignalMessageKeys.isReadField)

            t.column(SignalMessageKeys.errorKindField)

            t.column(SignalMessageKeys.groupMetaMessageTypeField)
            t.column(SignalMessageKeys.recipientIdField)
            t.column(SignalMessageKeys.messageStateField)

            t.column(SignalMessageKeys.attachmentIdsField)
        })

        // attachments
        _ = try? self.dbConnection.run(self.attachmentsTable.create { t in
            t.column(SignalAttachmentKeys.uniqueIdField, primaryKey: true)
            t.column(SignalAttachmentKeys.keyField)
            t.column(SignalAttachmentKeys.sizeField)
            t.column(SignalAttachmentKeys.stateField)
            t.column(SignalAttachmentKeys.digestField)
            t.column(SignalAttachmentKeys.serverIdField)
            t.column(SignalAttachmentKeys.contentTypeField)
            t.column(SignalAttachmentKeys.attachmentDataField)
        })

        // create recipients table
        _ = try? self.dbConnection.run(self.recipientsTable.create  { t in
            t.column(SignalRecipientKeys.nameField)
            t.column(SignalRecipientKeys.deviceIdField)
        })

        // create sender table
        _ = try? self.dbConnection.run(self.senderTable.create  { t in
            t.column(SignalSenderKeys.passwordField)
            t.column(SignalSenderKeys.remoteRegistrationIdField)
            t.column(SignalSenderKeys.usernameField)
            t.column(SignalSenderKeys.signalingKeyField)
            t.column(SignalSenderKeys.deviceIdField)
        })

        // create signal library table
        _ = try? self.dbConnection.run(self.signalLibraryTable.create  { t in
            t.column(SignalLibraryKeys.uniqueIdField, primaryKey: true)
            t.column(SignalLibraryKeys.identifierField)
            t.column(SignalLibraryKeys.dataField)
            t.column(SignalLibraryKeys.typeField)
        })

        // create user table
        _ = try? self.dbConnection.run(self.userTable.create  { t in
            t.column(UserKeys.passwordField)
            t.column(UserKeys.privateKeyField)
            t.column(UserKeys.usernameField)
            t.column(UserKeys.nameField)
            t.column(UserKeys.avatarField)
            t.column(UserKeys.descriptionField)

            t.unique([UserKeys.privateKeyField, UserKeys.usernameField])
        })

        // create contacts table
        _ = try? self.dbConnection.run(self.contactsTable.create  { t in
            t.column(UserKeys.addressField)
            t.column(UserKeys.usernameField)
            t.column(UserKeys.nameField)
            t.column(UserKeys.avatarField)
            t.column(UserKeys.descriptionField)

            t.unique([UserKeys.addressField, UserKeys.usernameField])
        })

        NSLog("Did finish database setup.")
    }

    func storeUser(_ user: Profile) {
        let insert = self.userTable.insert(
            UserKeys.passwordField <- user.password,
            UserKeys.privateKeyField <- user.cereal.privateKey,
            UserKeys.usernameField <- user.username,
            UserKeys.nameField <- user.name,
            UserKeys.avatarField <- user.avatar,
            UserKeys.descriptionField <- user.description
        )

        let existing = self.userTable.filter(UserKeys.privateKeyField == user.cereal.privateKey)

        do {
            if try self.dbConnection.scalar(existing.count) > 0 {
                try self.dbConnection.run(existing.delete())
            }

            try self.dbConnection.run(insert)
        } catch (let error as SQLite.Result) {
            if case SQLite.Result.error(let message, let code, _) = error {
                if code == 19 {
                    // Code 19 means we're violating the unique key constraint.
                    fatalError("Failed to store data in the db: \(message)")
                }
            }
        } catch {
            fatalError("Failed to store data in db with unknown error")
        }
    }

    func retrieveUser() -> Profile? {
        guard let userRow = try! self.dbConnection.pluck(self.userTable) else { return nil }

        let password = try! userRow.get(UserKeys.passwordField)
        let privateKey = try! userRow.get(UserKeys.privateKeyField)
        
        let username = try! userRow.get(UserKeys.usernameField)
        let name = try! userRow.get(UserKeys.nameField)
        let avatar = try! userRow.get(UserKeys.avatarField)
        let description = try! userRow.get(UserKeys.descriptionField)

        return Profile(password: password, privateKey: privateKey, username: username, name: name, avatar: avatar, description: description)
    }

    func storeContact(_ contact: Profile) {
        let insert: Insert = self.buildContactOperation(contact)
        self.insert(insert)
    }

    func updateContact(_ contact: Profile) {
        let update: Update = self.buildContactOperation(contact)
        self.update(update)
    }

    public func retrieveContacts() -> [Profile] {
        var contacts = [Profile]()
        let query = self.buildQuery(for: self.contactsTable)

        do {
            for contactRow in try self.dbConnection.prepare(query) {
                let address = try contactRow.get(UserKeys.addressField)
                let username = try contactRow.get(UserKeys.usernameField)
                let name = try contactRow.get(UserKeys.nameField) ?? ""
                let avatar = try contactRow.get(UserKeys.avatarField) ?? ""
                let description = try contactRow.get(UserKeys.descriptionField) ?? ""

                let contact = Profile(id: address, username: username, name: name, avatar: avatar, description: description)

                contacts.append(contact)
            }
        } catch {
            fatalError()
        }

        return contacts
    }

    private func insert(_ insert: Insert) {
        do {
            try self.dbConnection.run(insert)
        } catch (let error as SQLite.Result) {
            if case SQLite.Result.error(let message, let code, _) = error {
                if code == 19 {
                    // Code 19 means we're violating the unique key constraint.
                    fatalError("Failed to store data in the db: \(message)")
                }
            }
        } catch {
            fatalError("Failed to store data in db with unknown error")
        }
    }

    private func update(_ update: Update) {
        do {
            try self.dbConnection.run(update)
        } catch (let error as SQLite.Result) {
            if case SQLite.Result.error(let message, let code, _) = error {
                if code == 19 {
                    // Code 19 means we're violating the unique key constraint.
                    fatalError("Failed to store data in the db: \(message)")
                }
            }
        } catch {
            fatalError("Failed to store data in db with unknown error")
        }
    }

    private func buildQuery(for table: Table, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> Table {
        var query = table
        if let predicate = predicate {
            let expr = Expression<Bool>(predicate.predicateFormat, [])
            query = query.where(expr)

            if let sortDescriptors = sortDescriptors {
                let expr = sortDescriptors.compactMap { sd -> String? in
                    guard let key = sd.key else { return nil }

                    return "\"\(key)\" \(sd.ascending ? "ASC" : "DESC")"
                }
                query = query.order(expr.joined(separator: ", "))
            }
        }

        return query
    }

    private func buildAttachmentOperation<T: Expressible>(_ attachment: SignalServiceAttachmentPointer) -> T {
        let digest = Blob(bytes: attachment.digest.map({ b -> UInt8 in b }))
        let key = Blob(bytes: attachment.key.map({ b -> UInt8 in b }))

        let attachmentData = attachment.attachmentData ?? Data()
        let data = Blob(bytes: attachmentData.map({ b -> UInt8 in b }))

        let values = [
            SignalAttachmentKeys.uniqueIdField <- attachment.uniqueId,
            SignalAttachmentKeys.stateField <- Int64(attachment.state.rawValue),
            SignalAttachmentKeys.sizeField <- Int64(attachment.size),
            SignalAttachmentKeys.contentTypeField <- attachment.contentType,
            SignalAttachmentKeys.serverIdField <- String(attachment.serverId),

            SignalAttachmentKeys.digestField <- digest,
            SignalAttachmentKeys.keyField <- key,
            SignalAttachmentKeys.attachmentDataField <- data
        ]

        if T.self is Insert.Type {
            return self.attachmentsTable.insert(values) as! T
        } else if T.self is Update.Type {
            return self.attachmentsTable.filter(SignalAttachmentKeys.uniqueIdField == attachment.uniqueId).update(values) as! T
        } else {
            fatalError()
        }
    }

    private func buildContactOperation<T: Expressible>(_ contact: Profile) -> T {
        let values = [
            UserKeys.addressField <- contact.id,
            UserKeys.usernameField <- contact.username,
            UserKeys.nameField <- contact.name,
            UserKeys.avatarField <- contact.avatar,
            UserKeys.descriptionField <- contact.description
        ]

        if T.self is Insert.Type {
            return self.contactsTable.insert(values) as! T
        } else if T.self is Update.Type {
            return self.contactsTable.filter(UserKeys.addressField == contact.id).update(values) as! T
        } else {
            fatalError()
        }
    }

    private func buildMessageOperation<T: Expressible>(_ message: SignalMessage) -> T {
        let messageType: Int64?
        if let type = (message as? InfoSignalMessage)?.messageType.rawValue {
            messageType = Int64(type)
        } else {
            messageType = nil
        }

        let groupMetaType: Int64?
        if let metaType = (message as? OutgoingSignalMessage)?.groupMetaMessageType.rawValue {
            groupMetaType = Int64(metaType)
        } else {
            groupMetaType = nil
        }

        let messageState: Int64?
        if let state = (message as? OutgoingSignalMessage)?.messageState.rawValue {
            messageState = Int64(state)
        } else {
            messageState = nil
        }

        var kindRaw: Int64? = nil
        if let raw = (message as? ErrorSignalMessage)?.kind.rawValue {
            kindRaw = Int64(raw)
        }

        let values = [
            SignalMessageKeys.uniqueIdField <- message.uniqueId,
            SignalMessageKeys.bodyField <- message.body,
            SignalMessageKeys.chatIdField <- message.chatId,
            SignalMessageKeys.timestampField <- String(message.timestamp),

            // important so we can more easily decode later
            SignalMessageKeys.messageKindField <- SignalMessageKind(message).rawValue,

            // incoming or info
            SignalMessageKeys.senderIdField <- message.senderId,

            // info
            SignalMessageKeys.additionalInfoField <- (message as? InfoSignalMessage)?.additionalInfo,
            SignalMessageKeys.customMessageField <- (message as? InfoSignalMessage)?.customMessage,
            SignalMessageKeys.messageTypeField <- messageType,

            // incoming
            SignalMessageKeys.isReadField <- (message as? IncomingSignalMessage)?.isRead,

            // error
            SignalMessageKeys.errorKindField <- kindRaw,

            // outgoing
            SignalMessageKeys.groupMetaMessageTypeField <- groupMetaType,
            SignalMessageKeys.recipientIdField <- (message as? OutgoingSignalMessage)?.recipientId,
            SignalMessageKeys.messageStateField <- messageState,
            SignalMessageKeys.attachmentIdsField <- message.attachmentPointerIds.joined(separator: ","),
        ]

        if T.self is Insert.Type {
            return self.messagesTable.insert(values) as! T
        } else if T.self is Update.Type {
            return self.messagesTable.filter(SignalMessageKeys.uniqueIdField == message.uniqueId).update(values) as! T
        } else {
            fatalError()
        }
    }
}

extension FilePersistenceStore: PersistenceStore {
    /* Lower level signal library types */
    func deleteSignalLibraryValue(key: String, type: SignalLibraryStore.LibraryStoreType)  -> Bool {
        let result: Bool
        let delete = self.signalLibraryTable.filter(SignalLibraryKeys.identifierField == key && SignalLibraryKeys.typeField == type.rawValue)
        do {
            try self.dbConnection.run(delete.delete())

            result = try self.dbConnection.scalar(delete.count) == 0
        } catch (let error) {
            result = false
            NSLog("Failed to delete data in the db: %@", error.localizedDescription)
        }

        return result
    }

    func storeSignalLibraryValue(_ data: Data, key: String, type: SignalLibraryStore.LibraryStoreType) {
        let insert = self.signalLibraryTable.insert(SignalLibraryKeys.identifierField <- key, SignalLibraryKeys.dataField <- data, SignalLibraryKeys.typeField <- type.rawValue)

        do {
            try self.dbConnection.run(insert)
        } catch (let error as SQLite.Result) {
            if case SQLite.Result.error(let message, let code, _) = error {
                if code == 19 {
                    // Code 19 means we're violating the unique key constraint.
                    // In that case, we're regenerating data, and would rather keep the new one
                    // so we attempt to override it instead, by first deleting the outdated version
                    // and calling ourselves again. 😬
                    if self.deleteSignalLibraryValue(key: key, type: type) {
                        self.storeSignalLibraryValue(data, key: key, type: type)
                    } else {
                        NSLog("Failed to delete library data in the db: %@", message)
                    }
                } else {
                    NSLog("Failed to store library data in the db: %@", message)
                }
            }
        } catch {
            NSLog("Failed to store library data in db with unknown error")
        }
    }

    func retrieveSignalLibraryValue(key: String, type: SignalLibraryStore.LibraryStoreType) -> Data? {
        let result = self.signalLibraryTable.filter(SignalLibraryKeys.typeField == type.rawValue && SignalLibraryKeys.identifierField == key)
        var object: Data?

        do {
            object = try self.dbConnection.pluck(result)?[SignalLibraryKeys.dataField]
        } catch (let error) {
            NSLog("Could not retrieve data from db: %@", error.localizedDescription)
        }

        return object
    }

    func retrieveAllSignalLibraryValue(ofType type: SignalLibraryStore.LibraryStoreType) -> [Data] {
        let result = self.signalLibraryTable.filter(SignalLibraryKeys.typeField == type.rawValue)
        var objects = [Data]()

        do {
            for row in try self.dbConnection.prepare(result) {
                objects.append(row[SignalLibraryKeys.dataField])
            }
        } catch (let error) {
            NSLog("Could not retrieve data from db: %@", error.localizedDescription)
        }

        return objects
    }

    /* Signal service types */

    func updateMessage(_ message: SignalMessage, _ completion: () -> Void) {
        let update: Update = self.buildMessageOperation(message)

        self.update(update)
        completion()
    }

    func storeMessage(_ message: SignalMessage, _ completion: () -> Void) {
        let insert: Insert = self.buildMessageOperation(message)

        self.insert(insert)
        completion()
    }

    func deleteMessage(_ message: SignalMessage, _ completion: () -> Void) {
        let delete = self.messagesTable.filter(SignalMessageKeys.uniqueIdField == message.uniqueId)
        do {
            try self.dbConnection.run(delete.delete())
        } catch (let error) {
            NSLog("Failed to delete data in the db: %@", error.localizedDescription)
        }

        completion()
    }

    func updateChat(_ chat: SignalChat, _ completion: () -> Void) {
        let values = [
            SignalChatKeys.recipientIdentifierField <- chat.recipientIdentifier,
            SignalChatKeys.recipientIdentifiersField <- chat.recipients.map({ r in r.name }).joined(separator: ","),
            SignalChatKeys.nameField <- chat.name,
            SignalChatKeys.currentDraftField <- chat.currentDraft,
            SignalChatKeys.isMutedField <- chat.isMuted,
            SignalChatKeys.lastArchivalDateField <- chat.lastArchivalDate?.timeIntervalSinceReferenceDate
        ]

        let update = self.chatsTable.filter(SignalChatKeys.uniqueIdField == chat.uniqueId).update(values)
        self.update(update)

        completion()
    }

    func storeChat(_ chat: SignalChat, _ completion: () -> Void) {
        let insert = self.chatsTable.insert(
            SignalChatKeys.uniqueIdField <- chat.uniqueId,
            SignalChatKeys.recipientIdentifierField <- chat.recipientIdentifier,
            SignalChatKeys.recipientIdentifiersField <- chat.recipients.map({ r in r.name }).joined(separator: ","),
            SignalChatKeys.nameField <- chat.name,
            SignalChatKeys.currentDraftField <- chat.currentDraft,
            SignalChatKeys.isMutedField <- chat.isMuted,
            SignalChatKeys.lastArchivalDateField <- chat.lastArchivalDate?.timeIntervalSinceReferenceDate
        )

        self.insert(insert)

        completion()
    }

    func deleteChat(_ chat: SignalChat, _ completion: () -> Void) {
        let deleteMessages = self.messagesTable.filter(SignalMessageKeys.chatIdField == chat.uniqueId)
        let deleteChat = self.chatsTable.filter(SignalChatKeys.uniqueIdField == chat.uniqueId)

        do {
            try self.dbConnection.run(deleteMessages.delete())
            try self.dbConnection.run(deleteChat.delete())
        } catch (let error) {
            NSLog("Failed to delete data in the db: %@", error.localizedDescription)
        }

        completion()
    }

    func retrieveAllChats(sortDescriptors: [NSSortDescriptor]?) -> [SignalChat] {
        var chats = [SignalChat]()
        let query = self.buildQuery(for: self.chatsTable, sortDescriptors: sortDescriptors)

        do {
            for chat in try self.dbConnection.prepare(query) {
                let id = try chat.get(SignalChatKeys.uniqueIdField)
                let recipientId = try chat.get(SignalChatKeys.recipientIdentifierField)
                let recipientIds = try chat.get(SignalChatKeys.recipientIdentifiersField)?.split(separator: ",").map({ s in String(s) }) ?? []
                let name = try chat.get(SignalChatKeys.nameField)
                let draft = try chat.get(SignalChatKeys.currentDraftField)
                let isMuted = try chat.get(SignalChatKeys.isMutedField)
                let archivalDate = try chat.get(SignalChatKeys.lastArchivalDateField)

                let chat = SignalChat(recipientIdentifier: recipientId, recipientIdentifiers: recipientIds, name: name, draft: draft, isMuted: isMuted, archivalDate: archivalDate)
                chat.uniqueId = id
                
                chats.append(chat)
            }
        } catch {
            fatalError()
        }

        return chats
    }

    func updateRecipient(_ recipient: SignalAddress, _ completion: () -> Void) {
        NSLog("update recipient")
        completion()
    }

    func storeRecipient(_ recipient: SignalAddress, _ completion: () -> Void) {
        let insert = self.recipientsTable.insert(
            SignalRecipientKeys.nameField <- recipient.name,
            SignalRecipientKeys.deviceIdField <- Int64(recipient.deviceId)
        )

        self.insert(insert)
        completion()
    }

    func retrieveSender() -> SignalSender? {
        let query = self.buildQuery(for: self.senderTable)

        guard let senderRow = try! self.dbConnection.pluck(query) else { return nil }

        do {
            let deviceID = try senderRow.get(SignalSenderKeys.deviceIdField)
            let username = try senderRow.get(SignalSenderKeys.usernameField)
            let password = try senderRow.get(SignalSenderKeys.passwordField)
            let remoteRegistrationId = try senderRow.get(SignalSenderKeys.remoteRegistrationIdField)
            let signalingKey = try senderRow.get(SignalSenderKeys.signalingKeyField)

            return SignalSender(username: username, password: password, deviceId: Int32(deviceID), remoteRegistrationId: UInt32(remoteRegistrationId), signalingKey: signalingKey)
        } catch {
            fatalError()
        }

        return nil
    }

    func storeSender(_ sender: SignalSender, _ completion: () -> Void) {
        let insert = self.senderTable.insert(
            SignalSenderKeys.usernameField <- sender.username,
            SignalSenderKeys.deviceIdField <- Int64(sender.deviceId),
            SignalSenderKeys.passwordField <- sender.password,
            SignalSenderKeys.signalingKeyField <- sender.signalingKey,
            SignalSenderKeys.remoteRegistrationIdField <- Int64(sender.remoteRegistrationId)
        )


        self.insert(insert)
        completion()
    }

    func retrieveAttachments(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [SignalServiceAttachmentPointer] {
        let query = self.buildQuery(for: self.attachmentsTable, predicate: predicate, sortDescriptors: sortDescriptors)

        var attachments: [SignalServiceAttachmentPointer] = []

        do {
            for row in try! self.dbConnection.prepare(query) {
                attachments.append(try SignalServiceAttachmentPointer.build(from: row))
            }
        } catch {
            fatalError()
        }

        return attachments
    }

    func updateAttachment(_ attachment: SignalServiceAttachmentPointer, _ completion: () -> Void) {
        let update: Update = self.buildAttachmentOperation(attachment)

        try! self.dbConnection.run(update)

        completion()
    }

    func storeAttachment(_ attachment: SignalServiceAttachmentPointer, _ completion: () -> Void) {
        if (try! self.dbConnection.pluck(self.attachmentsTable.where(SignalAttachmentKeys.uniqueIdField == attachment.uniqueId)) != nil) {
            self.updateAttachment(attachment, completion)
        } else  {
            let insert: Insert = self.buildAttachmentOperation(attachment)

            try! self.dbConnection.run(insert)
        }

        completion()
    }

    func retrieveMessages(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [SignalMessage] {
        let query = self.buildQuery(for: self.messagesTable, predicate: predicate, sortDescriptors: sortDescriptors)

        var messages: [SignalMessage] = []

        do {
            for messageRow in try! self.dbConnection.prepare(query) {
                messages.append(try SignalMessage.build(from: messageRow))
            }
        } catch {
            fatalError()
        }

        return messages
    }

    func retrieveChats(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [SignalChat] {
        let query = self.buildQuery(for: self.chatsTable, predicate: predicate, sortDescriptors: sortDescriptors)

        var chats: [SignalChat] = []
        do {
            for chatRow in try! self.dbConnection.prepare(query) {
                let id = try chatRow.get(SignalChatKeys.uniqueIdField)
                let recipientId = try chatRow.get(SignalChatKeys.recipientIdentifierField)
                let recipientIds = try chatRow.get(SignalChatKeys.recipientIdentifiersField)?.split(separator: ",").map({ s in String(s) }) ?? []
                let name = try chatRow.get(SignalChatKeys.nameField)
                let draft = try chatRow.get(SignalChatKeys.currentDraftField)
                let isMuted = try chatRow.get(SignalChatKeys.isMutedField)
                let archivalDate = try chatRow.get(SignalChatKeys.lastArchivalDateField)

                let chat = SignalChat(recipientIdentifier: recipientId, recipientIdentifiers: recipientIds, name: name, draft: draft, isMuted: isMuted, archivalDate: archivalDate)
                chat.uniqueId = id

                chats.append(chat)
            }
        } catch {
            fatalError("Could not parse chat?")
        }

        return chats
    }

    func retrieveRecipients(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [SignalAddress] {
        let query = self.buildQuery(for: self.recipientsTable, predicate: predicate, sortDescriptors: sortDescriptors)

        var recipients: [SignalAddress] = []
        do {
            for recipientRow in try! self.dbConnection.prepare(query) {
                let name = try recipientRow.get(SignalRecipientKeys.nameField)
                let deviceId = try recipientRow.get(SignalRecipientKeys.deviceIdField)

                recipients.append(SignalAddress(name: name, deviceId: Int32(deviceId)))
            }
        } catch {
            fatalError("Could not parse chat?")
        }

        return recipients
    }

    func deleteAllChatsAndMessages(_ completion: () -> Void) {
        try! self.dbConnection.run(self.chatsTable.drop(ifExists: true))
        try! self.dbConnection.run(self.messagesTable.drop(ifExists: true))
        completion()
    }
}
