//
//  MessagesViewController.swift
//  SQLiteDemo
//
//  Created by Igor Ranieri on 20.04.18.
//

import Quetzalcoatl
import SweetUIKit
import UIKit

extension UIColor {
    static var darkGreen: UIColor {
        return #colorLiteral(red: 0.02588345483, green: 0.7590896487, blue: 0.2107430398, alpha: 1)
    }

    static var lightGray: UIColor {
        return #colorLiteral(red: 0.9254434109, green: 0.925465405, blue: 0.9339957833, alpha: 1)
    }
}

public extension CGFloat {
    /// The height of a single pixel on the screen.
    static var lineHeight: CGFloat {
        return 1 / UIScreen.main.scale
    }
}

protocol MessagesViewControllerDelegate {
    func didRequestSendMessage(text: String, in chat: SignalChat)

    func didRequestRetryMessage(message: OutgoingSignalMessage, to recipients: [SignalAddress])
    
    func didRequestNewIdentity(for address: SignalAddress, deleting message: SignalMessage)
}

class MessagesViewController: UIViewController {
    let chat: SignalChat

    var shouldScrollToBottom = false

    var messages: [SignalMessage] {
        return self.chat.visibleMessages
    }

//    let refreshControl = UIRefreshControl()

    lazy var chatInputViewController: ChatInputViewController = {
        let usernames = self.chat.recipients.map({ addr -> String in addr.name }).map({ name in ContactManager.displayName(for: name) })

        let chatInputVC = ChatInputViewController(usernames: usernames, delegate: self)
        chatInputVC.registerPrefixes(forAutoCompletion: ["@"])

        return chatInputVC
    }()

    var delegate: MessagesViewControllerDelegate?

    lazy var tableView: ChatTableView = {
        let view = ChatTableView(frame: .zero, style: .plain)

        view.dataSource = self
        view.delegate = self

        view.register(UITableViewCell.self)
        view.register(MessagesTextCell.self)
        view.register(StatusCell.self)

        return view
    }()

    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm dd/MM/yyyy"

        return dateFormatter
    }()

    init(chat: SignalChat) {
        self.chat = chat
        super.init(nibName: nil, bundle: nil)
        self.addChild(self.chatInputViewController)

        self.hidesBottomBarWhenPushed = true
        self.chatInputViewController.hidesBottomBarWhenPushed = true
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

        self.scrollTableViewToBottom(animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if self.shouldScrollToBottom {
            self.shouldScrollToBottom = false
            self.scrollTableViewToBottom(animated: false)
        }
    }

    private func scrollTableViewToBottom(animated: Bool) {
        guard !self.messages.isEmpty else { return }

        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
    }

    private func addSubviewsAndConstraints() {
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.chatInputViewController.view)

        self.navigationItem.title = self.chat.displayName

        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
        ])

        self.tableView.left(to: self.view)
        self.tableView.right(to: self.view)

        self.view.layoutIfNeeded()

        self.tableView.contentInset.bottom = self.chatInputViewController.textInputbar.frame.height
    }

    private func message(at indexPath: IndexPath) -> SignalMessage {
        return self.messages[indexPath.row]
    }
}

extension MessagesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = self.message(at: indexPath)
        if message is InfoSignalMessage {
            let alert = UIAlertController(title: "Accept new identity?", message: nil, preferredStyle: .actionSheet)
            let accept = UIAlertAction(title: "Accept", style: .default) { _ in
                guard let address = self.chat.recipients.first(where: { address -> Bool in
                    address.name == message.senderId
                }) else  {
                    fatalError("Could not restore identity for recipient")
                }

                self.delegate?.didRequestNewIdentity(for: address, deleting: message)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in

            }
            alert.addAction(accept)
            alert.addAction(cancel)

            self.present(alert, animated: true)
        }
    }
}

extension MessagesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.configuredCell(for: indexPath)
        cell.layoutIfNeeded()

        return cell
    }

    private func configuredCell(for indexPath: IndexPath) -> UITableViewCell {
        let message = self.message(at: indexPath)

        if let message = message as? InfoSignalMessage {
            let cell = self.tableView.dequeue(StatusCell.self, for: indexPath)

            let localizedFormat = NSLocalizedString(message.customMessage, comment: "")
            let contact = ContactManager.displayName(for: message.senderId)
            let string = String(format: localizedFormat, contact, message.additionalInfo)

            let attributed = NSMutableAttributedString(string: string)
            attributed.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 17), range: (string as NSString).range(of: contact))
            attributed.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 17), range: (string as NSString).range(of: message.additionalInfo))

            cell.textLabel?.attributedText = attributed

            return cell
        } else {
            let cell = self.tableView.dequeue(MessagesTextCell.self, for: indexPath)
            cell.indexPath = indexPath

            cell.delegate = self

            cell.isOutgoingMessage = message is OutgoingSignalMessage
            cell.messageBody = message.body // SofaMessage(content: message.body).body
            cell.avatar = ContactManager.image(for: message.senderId)

            cell.messageState = (message as? OutgoingSignalMessage)?.messageState ?? .none
//            cell.dateStrng = self.dateFormatter.string(from: Date(milisecondTimeIntervalSinceEpoch: message.timestamp))

            if let attachment = message.attachment, let image = UIImage(data: attachment) {
                cell.messageImage = image
            } else {
                cell.messageImage = nil
            }

            return cell
        }
    }
}

extension MessagesViewController: SignalServiceStoreMessageDelegate {
    func signalServiceStoreWillChangeMessages() {
        self.tableView.beginUpdates()
        self.shouldScrollToBottom = true
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
        self.tableView.endUpdates()

        if self.shouldScrollToBottom  {
            self.shouldScrollToBottom = false
            self.scrollTableViewToBottom(animated: true)
        }
    }
}

extension MessagesViewController: ChatInputViewControllerDelegate {
    func didSendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        self.shouldScrollToBottom = true
        self.delegate?.didRequestSendMessage(text: text, in: self.chat)
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
        guard let message = self.message(at: cell.indexPath) as? OutgoingSignalMessage else { fatalError("Trying to send a non-outgoing message!") }
        self.delegate?.didRequestRetryMessage(message: message, to: self.chat.recipients)
    }
}
