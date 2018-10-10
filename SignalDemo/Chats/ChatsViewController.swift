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
    var user: Profile {
        return Profile.current!
    }

    private(set) var chatsDataSource: ChatsDataSource!

    let idClient = IDAPIClient()

    let teapot = Teapot(baseURL: URL(string: "https://token-chat-service-development.herokuapp.com")!)

    lazy var quetzalcoatl: Quetzalcoatl = {
        let quetzalcoatl = Quetzalcoatl(baseURL: self.teapot.baseURL, recipientsDelegate: self, persistenceStore: self.persistenceStore)
        quetzalcoatl.store.chatDelegate = self

        return quetzalcoatl
    }()

    var persistenceStore = FilePersistenceStore()

    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.separatorStyle = .none
        view.delegate = self

        return view
    }()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        if let user = self.persistenceStore.retrieveUser() {
            Profile.current = user

            super.init(nibName: nil, bundle: nil)

            self.quetzalcoatl.startSocket()
            self.quetzalcoatl.shouldKeepSocketAlive = true

        } else {
            // cheating for testing
            // should be generated on registration instead
            let igor = "0989d7b7ccfe3baf39ed441d001df834173e0729916210d14f60068d1d22c595"
            let karina = "1989d7b7ccfe3baf39ed441d001df834173e0729916210d14f60068d1d22c595"
            let sim = "2989d7b7ccfe3baf39ed441d001df834173e0729916210d14f60068d1d22c595"
            let iPhone7 = "2989d7b7ccfe3baf3fa3441d001ff834173e0729916210d14f60068d1d22c595"

            Profile.current = Profile(password: UUID().uuidString, privateKey: igor)

            super.init(nibName: nil, bundle: nil)

            self.register(user: self.user)
        }

        NotificationCenter.default.addObserver(forName: Profile.didUpdateCurrentProfileNotification, object: nil, queue: .main) { _ in
            guard let profile = Profile.current else { return }

            self.persistenceStore.storeUser(profile)
        }

        self.quetzalcoatl.store.chatDelegate = self
        self.chatsDataSource = ChatsDataSource(tableView: self.tableView, quetzalcoatl: self.quetzalcoatl)
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

    func register(user: Profile) {
        self.fetchTimestamp { timestamp in
            let payload = self.quetzalcoatl.generateUserBootstrap(username: user.id, password: user.password)
            let path = "/v1/accounts/bootstrap"

            guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
                NSLog("Invalid JSON payload!")
                return
            }

            let payloadString = String(data: data, encoding: .utf8)!

            let hashedPayload = user.cereal.sha3(string: payloadString)
            let message = "PUT\n\(path)\n\(timestamp)\n\(hashedPayload)"
            let signature = "0x\(user.cereal.sign(message: message))"

            let fields: [String: String] = ["Token-ID-Address": user.cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]
            let requestParameter = RequestParameter(payload)

            self.teapot.put(path, parameters: requestParameter, headerFields: fields) { result in
                switch result {
                case .success(_, let response):
                    guard response.statusCode == 204 else {
                        fatalError()
                    }

                    self.idClient.registerUser(with: user.cereal, completion: { status in
                        NSLog("\(status.rawValue)")
                    })

                    self.quetzalcoatl.startSocket()
                    self.quetzalcoatl.shouldKeepSocketAlive = true
                    self.persistenceStore.storeUser(user)
                case .failure(_, _, let error):
                    NSLog(error.localizedDescription)
                    break
                }
            }
        }
    }

    func fetchTimestamp(_ completion: @escaping ((Int) -> Void)) {
        self.teapot.get("/v1/accounts/bootstrap/") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else { fatalError("Could not retrieve timestamp from chat service.") }
                guard let json = json?.dictionary else { fatalError("JSON dictionary not found in payload") }
                guard let timestamp = json["timestamp"] as? Int else { fatalError("Timestamp not found in json payload or not an integer.") }

                DispatchQueue.main.async {
                    completion(timestamp)
                }
            case .failure(_, _, let error):
                fatalError(error.localizedDescription)
            }
        }
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
        destination.delegate = self

        self.quetzalcoatl.store.messageDelegate = destination
        self.navigationController?.pushViewController(destination, animated: true)
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let chat = self.chatsDataSource.chats[indexPath.row]
            self.quetzalcoatl.deleteChat(chat)
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

        let chat = self.quetzalcoatl.store.fetchOrCreateChat(with: id)
        self.didRequestSendMessage(text: "", in: chat)
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

extension ChatsViewController: MessagesViewControllerDelegate {
    func didRequestRetryMessage(message: OutgoingSignalMessage, to recipients: [SignalAddress]) {
        self.quetzalcoatl.retryMessage(message, to: recipients)
    }
    
    func didRequestNewIdentity(for address: SignalAddress, deleting message: SignalMessage) {
        self.quetzalcoatl.requestNewIdentity(for: address)
        self.quetzalcoatl.deleteMessage(message)
    }

    static func randomMessage() -> (String, [UIImage]) {
        let messages: [(String, [UIImage])] = [
            (SofaMessage(body: "This is testing message from our Signal demo client.").content, []),
            (SofaMessage(body: "This is random message from SQLite demo.").content, []),
            (SofaMessage(body: "What's up, doc?.").content, [UIImage(named: "doc")!]),
            (SofaMessage(body: "This is Ceti Alpha 5!!!!!!!").content, [UIImage(named: "cetialpha5")!]),
            (SofaMessage(body: "Hey, this is a test with a slightly longer text, and some utf-32 characters as well. 👨‍👩‍👧☺️😇 Am I right? 👨🏿‍🔬. I am right…").content, [])
        ]

        let index = Int(arc4random() % UInt32(messages.count))

        return messages[index]
    }

    func didRequestSendMessage(text: String, in chat: SignalChat) {
        let (_, images) = ChatsViewController.randomMessage()
        let attachments = images.compactMap { img in img.pngData() }

        if chat.isGroupChat {
            self.quetzalcoatl.sendGroupMessage(text, type: .deliver, to: chat.recipients, attachments: attachments)
        } else {
            self.quetzalcoatl.sendMessage(text, to: chat.recipients.first!, in: chat, attachments: attachments)
        }
    }
}

extension ChatsViewController: SignalRecipientsDisplayDelegate {
    func displayName(for address: String) -> String {
        return ContactManager.displayName(for: address)
    }

    func image(for address: String) -> UIImage? {
        return ContactManager.image(for: address)
    }
}
