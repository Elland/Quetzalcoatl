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
        SessionManager.shared.chatDelegate = self.chatsDataSource

        NotificationCenter.default.addObserver(forName: ChatsDataSource.chatDidUpdateNotification, object: nil, queue: .main) { n in
            self.navigationController?.tabBarItem.badgeValue = (n.object as! Int) > 0 ? String((n.object as! Int)) : nil
        }
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let count = self.chatsDataSource.chats.map({$0.unreadCount}).reduce(0,+)
        self.navigationController?.tabBarItem.badgeValue = count > 0 ? String(count) : nil
    }

    @IBAction func didTapCreateChatButton(_ sender: Any) {
        let scannerController = ContactScannerViewController(instructions:  "", types: [.qrCode], startScanningAtLoad: true, showSwitchCameraButton: false, showTorchButton: false, alertIfUnavailable: true)

        scannerController.delegate = self
        self.navigationController?.pushViewController(scannerController, animated: true)
    }

    func openChat(_ chat: SignalChat, animated: Bool) {
        let destination = MessagesViewController(chat: chat)
        self.navigationController?.pushViewController(destination, animated: animated)
    }

    func openChat(with identifier: String, animated: Bool) {
        if let chat = self.chatsDataSource.chats.first(where: { s in s.uniqueId == identifier }) {
            self.openChat(chat, animated: animated)
        }
    }
}

extension ChatsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = self.chatsDataSource.chats[indexPath.row]
        self.openChat(chat, animated: true)
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
        guard let url = URL(string: result),
            url.scheme == "quetzalcoatl",
            let id = url.host
            else {
                controller.startScanning()
                return
        }

        self.navigationController?.popToViewController(self, animated: true)
        let contactViewController = ContactViewController.controller(with: id)
        self.navigationController?.pushViewController(contactViewController, animated: true)
//        _ = self.chatsDataSource.createChat(with: id)
    }

    func scannerViewControllerDidCancel(_ controller: ScannerViewController) {
        self.navigationController?.popViewController(animated: true)
    }
}
