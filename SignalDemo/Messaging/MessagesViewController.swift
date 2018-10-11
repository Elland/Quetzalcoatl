//
//  MessagesViewController.swift
//  SQLiteDemo
//
//  Created by Igor Ranieri on 20.04.18.
//

import Quetzalcoatl
import SweetUIKit
import UIKit

class MessagesViewController: UIViewController, MessageActionsDelegate {
    let chat: SignalChat
    private(set) var messagesDataSource: MessagesDataSource!

    private var quetzalcoatl: Quetzalcoatl {
        return SessionManager.shared.quetzalcoatl
    }

    var shouldScrollToBottom = false

    var messages: [SignalMessage] {
        return self.chat.visibleMessages
    }

    lazy var chatInputViewController: ChatInputViewController = {
        let usernames = self.chat.recipients.map({ addr -> String in addr.name }).map({ name in ContactManager.displayName(for: name) })

        let chatInputVC = ChatInputViewController(usernames: usernames, delegate: self)
        chatInputVC.registerPrefixes(forAutoCompletion: ["@"])

        return chatInputVC
    }()

    lazy var tableView: ChatTableView = {
        let view = ChatTableView(frame: .zero, style: .plain)

        view.delegate = self

        view.register(UITableViewCell.self)
        view.register(MessagesTextCell.self)
        view.register(StatusCell.self)

        return view
    }()

    lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView()

        return view
    }()

    init(chat: SignalChat) {
        self.chat = chat
        super.init(nibName: nil, bundle: nil)
        self.addChild(self.chatInputViewController)

        // TODO: fix this; this is dumb!
        self.messagesDataSource = MessagesDataSource(tableView: self.tableView, chat: self.chat)
        self.messagesDataSource.messageActionsDelegate = self

        self.hidesBottomBarWhenPushed = true
        self.chatInputViewController.hidesBottomBarWhenPushed = true

        NotificationCenter.default.addObserver(forName: AvatarManager.avatarDidUpdateNotification, object: nil, queue: .main) { notif in
            guard let id = notif.object as? String,
                self.chat.recipients.map({$0.name}).contains(id),
                let image  = notif.userInfo?["image"] as? UIImage
                else { return }

            self.avatarImageView.image = image
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var inputAccessoryView: UIView? {
        let view = UIView(frame: .zero)
        view.backgroundColor = .white

        return view
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
        self.addSubviewsAndConstraints()

        NotificationCenter.default.addObserver(self, selector: #selector(self.willShowOrHideKeyboard(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.willShowOrHideKeyboard(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didShowOrHideKeyboard(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didShowOrHideKeyboard(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)

        self.shouldScrollToBottom = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.chat.markAllAsRead()
        
        self.scrollTableViewToBottom(animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.chat.markAllAsRead()

        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if self.shouldScrollToBottom {
            self.shouldScrollToBottom = false
            self.scrollTableViewToBottom(animated: false)
        }
    }

    private func addSubviewsAndConstraints() {
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.chatInputViewController.view)

        self.navigationItem.title = self.chat.displayName
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.avatarImageView)

        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
        ])

        self.tableView.left(to: self.view)
        self.tableView.right(to: self.view)

        self.view.layoutIfNeeded()

        self.tableView.contentInset.bottom = self.chatInputViewController.textInputbar.frame.height
    }

    func scrollTableViewToBottom(animated: Bool) {
        guard !self.messages.isEmpty else { return }

        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
    }

    private func didRequestRetryMessage(message: OutgoingSignalMessage, to recipients: [SignalAddress]) {
        self.quetzalcoatl.retryMessage(message, to: recipients)
    }

    private func didRequestNewIdentity(for address: SignalAddress, deleting message: SignalMessage) {
        self.quetzalcoatl.requestNewIdentity(for: address)
        self.quetzalcoatl.deleteMessage(message)
    }

    private func didRequestSendMessage(text: String, in chat: SignalChat) {
        if chat.isGroupChat {
            self.quetzalcoatl.sendGroupMessage(text, type: .deliver, to: chat.recipients)
        } else {
            self.quetzalcoatl.sendMessage(text, to: chat.recipients.first!, in: chat)
        }
    }
}

extension MessagesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = self.messagesDataSource.message(at: indexPath)

        if message is InfoSignalMessage {
            let alert = UIAlertController(title: "Accept new identity?", message: nil, preferredStyle: .actionSheet)
            let accept = UIAlertAction(title: "Accept", style: .default) { _ in
                guard let address = self.chat.recipients.first(where: { address -> Bool in
                    address.name == message.senderId
                }) else  {
                    fatalError("Could not restore identity for recipient")
                }

                self.didRequestNewIdentity(for: address, deleting: message)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in

            }
            alert.addAction(accept)
            alert.addAction(cancel)

            self.present(alert, animated: true)
        } else if message is ErrorSignalMessage {
            let result = self.quetzalcoatl.libraryStore.deleteAllDeviceSessions(for: message.senderId)
            print(result)
        }
    }
}

extension MessagesViewController: ChatInputViewControllerDelegate {
    func didSendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        self.shouldScrollToBottom = true
        self.didRequestSendMessage(text: text, in: self.chat)
    }

    @objc func willShowOrHideKeyboard(_ notification: NSNotification) {
        guard let rect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { fatalError() }

        if notification.name == UIResponder.keyboardWillHideNotification {
            self.tableView.contentInset.bottom = self.chatInputViewController.textInputbar.frame.height
        } else {
            let diff = UIScreen.main.bounds.height - rect.origin.y
            self.tableView.contentInset.bottom = diff + self.chatInputViewController.textInputbar.frame.height
            self.scrollTableViewToBottom(animated: true)
        }

        self.view.layoutIfNeeded()
    }

    @objc func didShowOrHideKeyboard(_ notification: NSNotification) {

    }
}

extension MessagesViewController: MessagesTextCellDelegate {
    func didTapErrorView(for cell: MessagesTextCell) {
        guard let message = self.messagesDataSource.message(at: cell.indexPath) as? OutgoingSignalMessage else { fatalError("Trying to send a non-outgoing message!") }
        self.didRequestRetryMessage(message: message, to: self.chat.recipients)
    }
}
