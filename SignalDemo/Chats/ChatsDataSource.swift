//
//  ChatsDataSource.swift
//  Signal
//
//  Created by Igor Ranieri on 10.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import Quetzalcoatl

class ChatsDataSource: NSObject {
    let quetzalcoatl: Quetzalcoatl
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

    init(tableView: UITableView, quetzalcoatl: Quetzalcoatl) {
        self.tableView = tableView
        self.quetzalcoatl = quetzalcoatl

        super.init()

        self.tableView.dataSource = self
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

        if let message = chat.visibleMessages.last {
            cell.date = self.dateFormatter.string(from: Date(milisecondTimeIntervalSinceEpoch: message.timestamp))
        }
    }
}
