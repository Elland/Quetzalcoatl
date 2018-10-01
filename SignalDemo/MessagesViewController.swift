//
//  MessagesViewController.swift
//  SQLiteDemo
//
//  Created by Igor Ranieri on 20.04.18.
//  Copyright © 2018 Bakken&Bæck. All rights reserved.
//

import SignalServiceSwift
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

extension CGFloat {
    /// The height of a single pixel on the screen.
    static var lineHeight: CGFloat {
        return 1 / UIScreen.main.scale
    }
}

protocol MessagesViewControllerDelegate {
    func didRequestSendRandomMessage(in chat: SignalChat)
}

class MessagesViewController: UIViewController {
    let chat: SignalChat

    var shouldScrollToBottom = false

    lazy var messages: [SignalMessage] = {
        return self.chat.visibleMessages
    }()

    let refreshControl = UIRefreshControl()

    var delegate: MessagesViewControllerDelegate?

    var textBarHeightConstraint: NSLayoutConstraint!
    var textBarBottomConstraint: NSLayoutConstraint!

    lazy var textInputBar: SLKTextInputbar = {
        let view = SLKTextInputbar(textViewClass: SLKTextView.self)
        view.translatesAutoresizingMaskIntoConstraints = false
//        view.textView.delegate = self

        return view
    }()

    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.estimatedRowHeight = 64.0
        view.dataSource = self
        view.delegate = self
        view.separatorStyle = .none
        view.keyboardDismissMode = .interactive
        view.contentInsetAdjustmentBehavior = .always

        view.addSubview(self.refreshControl)

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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
        self.addSubviewsAndConstraints()

        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangeTextViewText(_:)), name: UITextView.textDidChangeNotification, object: nil)

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
            self.scrollTableViewToBottom(animated: true)
        }
    }

    private func scrollTableViewToBottom(animated: Bool) {
        guard !self.messages.isEmpty else { return }

        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .none, animated: animated)
    }

    private func addSubviewsAndConstraints() {
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.textInputBar)

        self.navigationItem.title = self.chat.displayName
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send random", style: .plain, target: self, action: #selector(self.sendRandomMessage(_:)))

        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.textInputBar.topAnchor),

            self.textInputBar.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.textInputBar.rightAnchor.constraint(equalTo: self.view.rightAnchor),
        ])

        self.textBarBottomConstraint = self.textInputBar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        self.textBarBottomConstraint.isActive = true

        self.textBarHeightConstraint = self.textInputBar.heightAnchor.constraint(greaterThanOrEqualToConstant: self.textInputBar.appropriateHeight)
        self.textBarHeightConstraint.isActive = true

        self.tableView.left(to: self.view)
        self.tableView.right(to: self.view)

        self.view.layoutIfNeeded()
    }

    @objc func sendRandomMessage(_ sender: Any) {
        self.shouldScrollToBottom = true
        self.delegate?.didRequestSendRandomMessage(in: self.chat)
    }

    private func message(at indexPath: IndexPath) -> SignalMessage {
        return self.messages[indexPath.row]
    }
}

extension MessagesViewController: UITableViewDelegate {

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
            cell.isOutgoingMessage = message is OutgoingSignalMessage
            cell.messageBody = SofaMessage(content: message.body).body

            //cell.sentState = (message as? OutgoingSignalMessage)?.messageState ?? .none
            //cell.text = self.dateFormatter.string(from: Date(milisecondTimeIntervalSinceEpoch: message.timestamp))

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
    }

    func signalServiceStoreDidChangeMessage(_ message: SignalMessage, at indexPath: IndexPath, for changeType: SignalServiceStore.ChangeType) {
        guard message.chatId == self.chat.uniqueId else { return }

        switch changeType {
        case .insert:
            (message as? IncomingSignalMessage)?.isRead = true
            self.messages.append(message)
            self.tableView.insertRows(at: [indexPath], with: .middle)
        case .delete:
            self.tableView.deleteRows(at: [indexPath], with: .right)
        case .update:
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }

    func signalServiceStoreDidChangeMessages() {
        self.tableView.endUpdates()

        if self.shouldScrollToBottom {
            self.shouldScrollToBottom = false
            self.scrollTableViewToBottom(animated: true)
        }
    }
}

extension MessagesViewController {
    @objc func willShowOrHideKeyboard(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        let screenHeight = UIScreen.main.bounds.height

        if notification.name == UIResponder.keyboardWillShowNotification {
            self.textBarBottomConstraint.constant = -(screenHeight - self.view.safeAreaInsets.bottom - endFrame.origin.y)
        } else {
            self.textBarBottomConstraint.constant = 0
        }

        self.view.layoutIfNeeded()
    }

    @objc func didShowOrHideKeyboard(_ notification: NSNotification) {

    }

    @objc func didChangeTextViewText(_ notification: NSNotification) {
        guard let view = notification.object as? SLKTextView, view  == self.textInputBar.textView else { return }

        // Animated only if the view already appeared.
        self.textDidUpdate()

        self.processTextForAutoCompletion()
    }

    func textDidUpdate() {
        let inputBarHeight = self.textInputBar.appropriateHeight

        defer {
            self.textInputBar.rightButton.isEnabled = self.canSendText()
            self.view.layoutIfNeeded()
        }

        guard self.textBarHeightConstraint.constant != inputBarHeight else {
            return
        }

        //let inputBarHeightDelta = inputBarHeight - self.textBarHeightConstraint.constant
        //let newOffset = CGPoint(x: 0, y: self.tableView.contentOffset.y + inputBarHeightDelta)
        self.textBarHeightConstraint.constant = inputBarHeight
    }

    func processTextForAutoCompletion() {

    }

    func canSendText() -> Bool {
        return !self.textInputBar.textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
