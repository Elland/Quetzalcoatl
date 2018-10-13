//
//  MessagesDataSource.swift
//  Signal
//
//  Created by Igor Ranieri on 11.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import Quetzalcoatl
import SweetUIKit
import UIKit

protocol MessageActionsDelegate: MessagesTextCellDelegate {
    var shouldScrollToBottom: Bool { get set }

    func scrollTableViewToBottom(animated: Bool)
}

class MessagesDataSource: NSObject {
    var quetzalcoatl: Quetzalcoatl {
        return SessionManager.shared.quetzalcoatl
    }

    unowned let tableView: UITableView

    weak var messageActionsDelegate: MessageActionsDelegate?

    private var _cachedMessages: [SignalMessage]

    private var messages: [SignalMessage] {
        return self._cachedMessages
    }

    private var chat: SignalChat

    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm dd/MM/yyyy"

        return dateFormatter
    }()

    init(tableView: UITableView, chat: SignalChat) {
        self.tableView = tableView
        self.chat = chat

        self._cachedMessages = self.chat.visibleMessages

        super.init()

        SessionManager.shared.messageDelegate = self
        self.tableView.dataSource = self
    }

    func message(at indexPath: IndexPath) -> SignalMessage {
        return self.messages[indexPath.row]
    }
}

extension MessagesDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.configuredCell(for: indexPath)

        return cell
    }

    func configuredCell(for indexPath: IndexPath) -> UITableViewCell {
        let message = self.message(at: indexPath)

        if let message = message as? InfoSignalMessage {
            let cell = self.tableView.dequeue(StatusCell.self, for: indexPath)

            return self.configuredStatusCell(cell, with: message)
        } else {
            let cell = self.tableView.dequeue(MessagesTextCell.self, for: indexPath)
            return self.configuredTextCell(cell, with: message)
        }
    }

    func configuredStatusCell(_ cell: StatusCell, with message: InfoSignalMessage) -> StatusCell {
        let localizedFormat = NSLocalizedString(message.customMessage, comment: "")
        let contact = SessionManager.shared.contactManager.displayName(for: message.senderId)
        let string = String(format: localizedFormat, contact, message.additionalInfo)

        let attributed = NSMutableAttributedString(string: string)
        attributed.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 17), range: (string as NSString).range(of: contact))
        attributed.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 17), range: (string as NSString).range(of: message.additionalInfo))

        cell.textLabel?.attributedText = attributed

        return cell
    }

    func configuredTextCell(_ cell: MessagesTextCell, with message: SignalMessage) -> MessagesTextCell {
        cell.delegate = self.messageActionsDelegate

        cell.isOutgoingMessage = message is OutgoingSignalMessage
        cell.messageBody = message.body // SofaMessage(content: message.body).body
        cell.avatar = SessionManager.shared.contactManager.image(for: message.senderId)

        cell.messageState = (message as? OutgoingSignalMessage)?.messageState ?? .none

        if let attachment = message.attachment, let image = UIImage(data: attachment) {
            cell.messageImage = image
        } else {
            cell.messageImage = nil
        }

        return cell

    }
}

extension MessagesDataSource: SignalServiceStoreMessageDelegate {
    func signalServiceStoreWillChangeMessages() {
        self.tableView.beginUpdates()

        self.messageActionsDelegate?.shouldScrollToBottom = true
    }

    func signalServiceStoreDidChangeMessage(_ message: SignalMessage, at indexPath: IndexPath, for changeType: SignalServiceStore.ChangeType) {
        guard message.chatId == self.chat.uniqueId else { return }

        switch changeType {
        case .insert:
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        case .delete:
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        case .update:
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }

    func signalServiceStoreDidChangeMessages() {
        // invalidate cache
        self._cachedMessages = self.chat.visibleMessages
        self.tableView.endUpdates()

        if self.messageActionsDelegate?.shouldScrollToBottom ?? false  {
            self.messageActionsDelegate?.shouldScrollToBottom = false
            self.messageActionsDelegate?.scrollTableViewToBottom(animated: true)
        }
    }
}
