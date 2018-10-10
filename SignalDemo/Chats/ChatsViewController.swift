//
//  ChatsViewController.swift
//  SQLiteDemo
//
//  Created by Igor Ranieri on 20.04.18.
//

import EtherealCereal
import Quetzalcoatl
import CameraScanner
import Teapot
import UIKit

class ChatsViewController: UIViewController {
    private(set) var chatsDataSource: ChatsDataSource!

    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.separatorStyle = .none
        view.delegate = self

        return view
    }()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)

        self.chatsDataSource = ChatsDataSource(tableView: self.tableView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let createChatButton = UIBarButtonItem(title: "Create chat", style: .plain, target: self, action: #selector(self.didTapCreateChatButton(_:)))
        self.navigationItem.rightBarButtonItem = createChatButton

        self.tableView.register(ChatCell.self)

        self.view.addSubview(self.tableView)
        self.tableView.fillSuperview()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @IBAction func didTapCreateChatButton(_ sender: Any) {
        let scannerController = ContactScannerViewController(instructions:  "", types: [.qrCode], startScanningAtLoad: true, showSwitchCameraButton: false, showTorchButton: false, alertIfUnavailable: true)
        scannerController.delegate = self
        self.navigationController?.pushViewController(scannerController, animated: true)
    }
}

extension ChatsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = self.chatsDataSource.chats[indexPath.row]

        let destination = MessagesViewController(chat: chat)
//        destination.delegate = self
//        self.quetzalcoatl.store.messageDelegate = destination

        self.navigationController?.pushViewController(destination, animated: true)
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let chat = self.chatsDataSource.chats[indexPath.row]

            self.chatsDataSource.deleteChat(chat)
        }

        return [deleteAction]
    }
}

extension ChatsViewController: ScannerViewControllerDelegate {
    func scannerViewController(_ controller: ScannerViewController, didScanResult result: String) {
        defer {
            self.navigationController?.popToViewController(self, animated: true)
        }

        guard let url = URL(string: result),
            url.scheme == "quetzalcoatl",
            let id = url.host
            else {
                controller.startScanning()
                return
        }

        let chat = self.chatsDataSource.createChat(with: id)
    }

    func scannerViewControllerDidCancel(_ controller: ScannerViewController) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension ChatsViewController: SignalServiceStoreChatDelegate {
    func signalServiceStoreWillChangeChats() {
    }

    func signalServiceStoreDidChangeChat(_ chat: SignalChat, at indexPath: IndexPath, for changeType: SignalServiceStore.ChangeType) {
    }

    func signalServiceStoreDidChangeChats() {
        self.tableView.reloadData()
    }
}

//extension ChatsViewController: MessagesViewControllerDelegate {
//    func didRequestRetryMessage(message: OutgoingSignalMessage, to recipients: [SignalAddress]) {
//        self.quetzalcoatl.retryMessage(message, to: recipients)
//    }
//
//    func didRequestNewIdentity(for address: SignalAddress, deleting message: SignalMessage) {
//        self.quetzalcoatl.requestNewIdentity(for: address)
//        self.quetzalcoatl.deleteMessage(message)
//    }
//
//    static func randomMessage() -> (String, [UIImage]) {
//        let messages: [(String, [UIImage])] = [
//            (SofaMessage(body: "This is testing message from our Signal demo client.").content, []),
//            (SofaMessage(body: "This is random message from SQLite demo.").content, []),
//            (SofaMessage(body: "What's up, doc?.").content, [UIImage(named: "doc")!]),
//            (SofaMessage(body: "This is Ceti Alpha 5!!!!!!!").content, [UIImage(named: "cetialpha5")!]),
//            (SofaMessage(body: "Hey, this is a test with a slightly longer text, and some utf-32 characters as well. 👨‍👩‍👧☺️😇 Am I right? 👨🏿‍🔬. I am right…").content, [])
//        ]
//
//        let index = Int(arc4random() % UInt32(messages.count))
//
//        return messages[index]
//    }
//
//    func didRequestSendMessage(text: String, in chat: SignalChat) {
//        let (_, images) = ChatsViewController.randomMessage()
//        let attachments = images.compactMap { img in img.pngData() }
//
//        if chat.isGroupChat {
//            self.quetzalcoatl.sendGroupMessage(text, type: .deliver, to: chat.recipients, attachments: attachments)
//        } else {
//            self.quetzalcoatl.sendMessage(text, to: chat.recipients.first!, in: chat, attachments: attachments)
//        }
//    }
//}
