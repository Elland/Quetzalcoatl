//
//  ChatsDataSource.swift
//  Signal
//
//  Created by Igor Ranieri on 10.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import Quetzalcoatl

class ChatsDataSource: NSObject {
    static let chatDidUpdateNotification = Notification.Name(rawValue: "ChatsDataSource.chatDidUpdateNotification")

    var quetzalcoatl: Quetzalcoatl {
        return SessionManager.shared.quetzalcoatl
    }

    unowned let tableView: UITableView

    var chats: [SignalChat] {
        get {
            return self.quetzalcoatl.store
                .retrieveAllChats(sortDescriptors: nil)
                .sorted(by: {a, b -> Bool in a.lastMessageDate?.compare(b.lastMessageDate ?? Date()) == .orderedDescending})
        }
    }

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm dd/mm/yyyy"

        return dateFormatter
    }()

    init(tableView: UITableView) {
        self.tableView = tableView

        super.init()

        self.tableView.dataSource = self
    }

    func createChat(with id: String) -> SignalChat {
        let chat = self.quetzalcoatl.store.fetchOrCreateChat(with: id)

        if chat.messages.isEmpty {
            if chat.isGroupChat {
                self.quetzalcoatl.sendGroupMessage("", type: .deliver, to: chat.recipients)
            } else {
                self.quetzalcoatl.sendMessage("", to: chat.recipients.first!, in: chat)
            }
        }

        return chat
    }

    func deleteChat(_ chat: SignalChat) {
        self.quetzalcoatl.deleteChat(chat)
    }
}

extension ChatsDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ChatCell.self, for: indexPath)

        self.configureCell(cell, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    private func configureCell(_ cell: ChatCell, at indexPath: IndexPath) {
        let chat = self.chats[indexPath.row]
        cell.title = chat.displayName
        cell.avatarImage = chat.image

        cell.unreadCount = chat.unreadCount

        if let message = chat.visibleMessages.last {
            cell.date = self.dateFormatter.string(from: Date(milisecondTimeIntervalSinceEpoch: message.timestamp))
        }
    }
}

extension ChatsDataSource: SignalServiceStoreChatDelegate {
    func signalServiceStoreWillChangeChats() {
        
    }

    func signalServiceStoreDidChangeChat(_ chat: SignalChat, at indexPath: IndexPath, for changeType: SignalServiceStore.ChangeType) {

    }

    func signalServiceStoreDidChangeChats() {
        self.tableView.reloadData()

        let count = self.chats.map { chat -> Int in chat.unreadCount }

        let total = count.reduce(0, +)

        NotificationCenter.default.post(name: ChatsDataSource.chatDidUpdateNotification, object: total)
    }
}
