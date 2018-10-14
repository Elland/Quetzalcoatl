//
//  SignalServiceStore.swift
//  Quetzalcoatl
//
//  Created by Igor Ranieri on 17.04.18.
//

public protocol PersistenceStore: SignalLibraryStoreDelegate {
    typealias PersistenceCompletionBlock = () -> Void

    /* Messages */
    func retrieveMessages(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [SignalMessage]

    func updateMessage(_ message: SignalMessage, _ completion: PersistenceCompletionBlock)
    func storeMessage(_  message: SignalMessage, _ completion: PersistenceCompletionBlock)
    func deleteMessage(_ message: SignalMessage, _ completion: PersistenceCompletionBlock)

    /* Chats */
    func retrieveAllChats(sortDescriptors: [NSSortDescriptor]?) -> [SignalChat]

    func retrieveChats(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [SignalChat]

    func updateChat(_ chat: SignalChat, _ completion: PersistenceCompletionBlock)
    func storeChat(_  chat: SignalChat, _ completion: PersistenceCompletionBlock)
    func deleteChat(_ chat: SignalChat, _ completion: PersistenceCompletionBlock)

    /* Recipients */
    func retrieveRecipients(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [SignalAddress]

    func updateRecipient(_ recipient: SignalAddress, _ completion: PersistenceCompletionBlock)
    func storeRecipient(_  recipient: SignalAddress, _ completion: PersistenceCompletionBlock)

    /* Sender */
    func retrieveSender() -> SignalSender?
    func storeSender(_  sender: SignalSender, _ completion: PersistenceCompletionBlock)

    /* Attachments */
    func retrieveAttachments(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [SignalServiceAttachmentPointer]

    func updateAttachment(_ attachment: SignalServiceAttachmentPointer, _ completion: PersistenceCompletionBlock)
    func storeAttachment(_  attachment: SignalServiceAttachmentPointer, _ completion: PersistenceCompletionBlock)

    /* Delete all chats and messages */
    func deleteAllChatsAndMessages(_ completion: PersistenceCompletionBlock)
}

public protocol SignalServiceStoreChatDelegate {
    func signalServiceStoreWillChangeChats()
    func signalServiceStoreDidChangeChat(_ chat: SignalChat, at indexPath: IndexPath, for changeType: SignalServiceStore.ChangeType)
    func signalServiceStoreDidChangeChats()
}

public protocol SignalServiceStoreMessageDelegate {
    func signalServiceStoreWillChangeMessages()
    func signalServiceStoreDidChangeMessage(_ message: SignalMessage, at indexPath: IndexPath, for changeType: SignalServiceStore.ChangeType)
    func signalServiceStoreDidChangeMessages()
}

public class SignalServiceStore {
    public enum ChangeType {
        case insert
        case update
        case delete
    }

    public enum PersistedType: String {
        case chat
        case message
        case recipient
        case attachmentPointer
        case sender
    }

    public var chatDelegates: [SignalServiceStoreChatDelegate] = []
    public var messageDelegates: [SignalServiceStoreMessageDelegate] = []
    public var contactsDelegate: SignalRecipientsDisplayDelegate

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private var persistenceStore: PersistenceStore

    public init(persistenceStore: PersistenceStore, contactsDelegate: SignalRecipientsDisplayDelegate) {
        self.contactsDelegate = contactsDelegate
        self.persistenceStore = persistenceStore
    }

    func fetchSender() -> SignalSender? {
        return self.persistenceStore.retrieveSender()
    }

    func storeSender(_ sender: SignalSender) {
        self.persistenceStore.storeSender(sender) {}
    }

    func fetchOrCreateRecipient(name: String, deviceId: Int32) -> SignalAddress {
        let recipient: SignalAddress

        if let existingRecipient = self.persistenceStore.retrieveRecipients(with: NSPredicate(format: "%K == %@ && %K == %d", "name", name, "deviceId", deviceId), sortDescriptors: nil).first {
            recipient = existingRecipient
        } else {
            recipient = SignalAddress(name: name, deviceId: deviceId)

            do {
                try self.save(recipient)
            } catch (let error) {
                NSLog("Could not save recipient: %@", error.localizedDescription)
            }
        }

        return recipient
    }

    public func fetchOrCreateChat(with recipientIdentifier: String) -> SignalChat {
        if let chat = self.chat(recipientIdentifier: recipientIdentifier) {
            chat.store = self
            chat.contactsDelegate = self.contactsDelegate

            return chat
        } else {
            let chat = SignalChat(recipientIdentifier: recipientIdentifier, in: self)
            chat.contactsDelegate = self.contactsDelegate
            chat.store = self

            do {
                try self.save(chat)
            } catch (let error) {
                NSLog("Could not save chat: %@", error.localizedDescription)
            }

            return chat
        }
    }

    public func fetchOrCreateChat(with recipientIdentifiers: [String]) -> SignalChat {
        if let chat = self.groupChat(recipientIdentifiers: recipientIdentifiers) {
            chat.store = self
            return chat
        } else {
            let chat = SignalChat(recipientIdentifiers: recipientIdentifiers, in: self)
            chat.contactsDelegate = self.contactsDelegate
            chat.store = self

            do {
                try self.save(chat)
            } catch (let error) {
                NSLog("Could not save chat: %@", error.localizedDescription)
            }

            return chat
        }
    }

    func fetchOrCreateChat(groupId: String, members: [String]) -> SignalChat {
        if let chat = self.groupChat(groupId: groupId) {
            chat.store = self
            chat.contactsDelegate = self.contactsDelegate

            return chat
        } else {
            let chat = SignalChat(recipientIdentifiers: members, in: self)
            chat.uniqueId = groupId
            chat.contactsDelegate = self.contactsDelegate
            chat.store = self

            do {
                try self.save(chat)
            } catch (let error) {
                NSLog("Could not save chat: %@", error.localizedDescription)
            }

            return chat
        }
    }

    func recipients(with identifiers: [String]) -> [SignalAddress] {
        let recipients = identifiers.map { identifier -> SignalAddress in
            self.fetchOrCreateRecipient(name: identifier, deviceId: 1)
        }

        return recipients
    }

    func attachment(with id: String) -> SignalServiceAttachmentPointer? {
        return self.persistenceStore.retrieveAttachments(with: NSPredicate(format: "%K == %@", "id", id), sortDescriptors: nil).first
    }

    func chat(recipientIdentifier: String) -> SignalChat? {
        return self.persistenceStore.retrieveChats(with: NSPredicate(format: "%K == %@", "recipientId", recipientIdentifier), sortDescriptors: [NSSortDescriptor(key: "timestamp", ascending: true), NSSortDescriptor(key: "name", ascending: false)]).first
    }

    func groupChat(recipientIdentifiers: [String]) -> SignalChat? {
        return self.persistenceStore.retrieveChats(with: NSPredicate(format: "%K == %@", "recipientIds", recipientIdentifiers.joined(separator: ",")), sortDescriptors: nil).first
    }

    func groupChat(groupId: String) -> SignalChat? {
        return self.persistenceStore.retrieveChats(with: NSPredicate(format: "%K == %@", "id", groupId), sortDescriptors: nil).first
    }

    public func retrieveAllChats(sortDescriptors: [NSSortDescriptor]?) -> [SignalChat] {
        let chats = self.persistenceStore.retrieveAllChats(sortDescriptors: sortDescriptors)

        chats.forEach { chat in
            chat.store = self
            chat.contactsDelegate = self.contactsDelegate
        }

        return chats
    }

    public func chat(chatId: String) -> SignalChat? {
        let chat = self.persistenceStore.retrieveChats(with: NSPredicate(format: "%K == %@", "id", chatId), sortDescriptors: nil).first
        chat?.store = self
        chat?.contactsDelegate = self.contactsDelegate

        return chat
    }

    public func messages(for chat: SignalChat, range: Range<Int>) -> [SignalMessage] {
        let messages = self.persistenceStore.retrieveMessages(with: NSPredicate(format: "%K == %@", "chatId", chat.uniqueId), sortDescriptors: [NSSortDescriptor(key: "timestamp", ascending: true)])

        messages.forEach { m in m.store = self }

        return messages
    }

    func save(_ recipient: SignalAddress) throws {
        self.persistenceStore.storeRecipient(recipient) {}
    }

    func chatContainsMessage(_ chat: SignalChat, _ message: SignalMessage) -> Bool {
        let messages = self.persistenceStore.retrieveMessages(with: NSPredicate(format: "%K == %lld && %K == %@", "timestamp", message.timestamp, "chatId", message.chatId), sortDescriptors: nil)

        return !messages.isEmpty
    }

    func save(_ message: SignalMessage) throws {
        message.store = self
        
        // update?
        if let chat = self.chat(chatId: message.chatId), self.chatContainsMessage(chat, message) {
            self.persistenceStore.updateMessage(message) {
                guard let visibleIndex = chat.visibleMessages.index(of: message) else {
                    NSLog("Message type not visible in chat.")
                    return
                }

                let indexPath = IndexPath(item: visibleIndex, section: 0)

                DispatchQueue.main.async {
                    self.messageDelegates.forEach({ $0.signalServiceStoreWillChangeMessages() })
                    self.messageDelegates.forEach({ $0.signalServiceStoreDidChangeMessage(message, at: indexPath, for: .update) })
                    self.messageDelegates.forEach({ $0.signalServiceStoreDidChangeMessages() })
                }

                try? self.save(chat)
            }
        } else {
            // new message
            if let chat = self.chat(chatId: message.chatId) {
                self.persistenceStore.storeMessage(message) {
                    guard message.isVisible else {
                        NSLog("Message type not visible in chat.")
                        return
                    }

                    DispatchQueue.main.async {
                        self.messageDelegates.forEach({ $0.signalServiceStoreWillChangeMessages() })
                    }

                    let index = chat.visibleMessages.index(of: message)!
                    let indexPath = IndexPath(item: index, section: 0)

                    DispatchQueue.main.async {
                        self.messageDelegates.forEach({ $0.signalServiceStoreDidChangeMessage(message, at: indexPath, for: .insert) })
                        self.messageDelegates.forEach({ $0.signalServiceStoreDidChangeMessages() })
                    }

                    try? self.save(chat)
                }
            } else {
                NSLog("Error: No chat for message: \(message).")
            }
        }
    }

    func delete(_ message: SignalMessage) throws {
        guard let chat = self.chat(chatId: message.chatId), message.isVisible else {
            NSLog("Message type not visible in chat.")
            return
        }

        DispatchQueue.main.async {
            self.messageDelegates.forEach({ $0.signalServiceStoreWillChangeMessages() })
        }

        let index = chat.visibleMessages.index(of: message)!
        let indexPath = IndexPath(item: index, section: 0)

        self.persistenceStore.deleteMessage(message) {
            DispatchQueue.main.async {
                self.messageDelegates.forEach({ $0.signalServiceStoreDidChangeMessage(message, at: indexPath, for: .delete) })
                self.messageDelegates.forEach({ $0.signalServiceStoreDidChangeMessages() })
            }
        }
    }

    func delete(_ chat: SignalChat) throws {
        DispatchQueue.main.async {
            self.chatDelegates.forEach({ $0.signalServiceStoreWillChangeChats() })
        }

        self.persistenceStore.deleteChat(chat) {
            DispatchQueue.main.async {
                self.chatDelegates.forEach({ $0.signalServiceStoreDidChangeChat(chat, at: IndexPath(item: 0, section: 0), for: .delete) })
                self.chatDelegates.forEach({ $0.signalServiceStoreDidChangeChats() })
            }
        }
    }

    func save(_ chat: SignalChat) throws {
        DispatchQueue.main.async {
            self.chatDelegates.forEach({ $0.signalServiceStoreWillChangeChats() })
        }

        // insert
        if self.chat(chatId: chat.uniqueId) == nil {
            self.persistenceStore.storeChat(chat)  {
                let indexPath = IndexPath(item: 0, section: 0)
                DispatchQueue.main.async {
                    self.chatDelegates.forEach({ $0.signalServiceStoreDidChangeChat(chat, at: indexPath, for: .insert) })
                    self.chatDelegates.forEach({ $0.signalServiceStoreDidChangeChats() })
                }
            }
        } else {
            // update
            self.persistenceStore.updateChat(chat) {
                let indexPath = IndexPath(item: 0, section: 0)

                DispatchQueue.main.async {
                    self.chatDelegates.forEach({ $0.signalServiceStoreDidChangeChat(chat, at: indexPath, for: .update) })
                    self.chatDelegates.forEach({ $0.signalServiceStoreDidChangeChats() })
                }
            }
        }
    }

    func save(attachmentPointer: SignalServiceAttachmentPointer) throws {
        self.persistenceStore.storeAttachment(attachmentPointer) { }
    }

    func deleteAllChatsAndMessages() {
        self.persistenceStore.deleteAllChatsAndMessages() { }
    }
}
