//
//  ChatsViewController.swift
//  SQLiteDemo
//
//  Created by Igor Ranieri on 20.04.18.
//

import EtherealCereal
import Quetzalcoatl
import Teapot
import UIKit

class ChatsViewController: UIViewController {
    var user: Profile {
        return Profile.current!
    }

    let igorContact = SignalAddress(name: "0x94b7382e8cbd02fc7bfd2e233e42b778ac2ce224", deviceId: 1)
    let karinaContact = SignalAddress(name: "0xcc4886677b6f60e346fe48968189c1b1fe9f3b33", deviceId: 1)

    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm dd/mm/yyyy"

        return dateFormatter
    }()

    let idClient = IDAPIClient()

    let teapot = Teapot(baseURL: URL(string: "https://token-chat-service-development.herokuapp.com")!)

    lazy var quetzalcoatl: Quetzalcoatl = {
        let quetzalcoatl = Quetzalcoatl(baseURL: self.teapot.baseURL, recipientsDelegate: self, persistenceStore: self.persistenceStore)
        quetzalcoatl.store.chatDelegate = self

        return quetzalcoatl
    }()

    var persistenceStore = FilePersistenceStore()

    var chats: [SignalChat] = []

    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.separatorStyle = .none
        view.delegate = self
        view.dataSource = self

        return view
    }()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        if let user = self.persistenceStore.retrieveUser() {
            Profile.current = user

            super.init(nibName: nil, bundle: nil)

            self.quetzalcoatl.startSocket()
            self.quetzalcoatl.shouldKeepSocketAlive = true
            self.chats = self.quetzalcoatl.store.retrieveAllChats()

        } else {
            // cheating for testing
            // should be generated on registration instead
            let igor = "0989d7b7ccfe3baf39ed441d001df834173e0729916210d14f60068d1d22c595"
            let karina = "1989d7b7ccfe3baf39ed441d001df834173e0729916210d14f60068d1d22c595"
            let sim = "2989d7b7ccfe3baf39ed441d001df834173e0729916210d14f60068d1d22c595"

            Profile.current = Profile(password: UUID().uuidString, privateKey: igor)

            super.init(nibName: nil, bundle: nil)

            self.register(user: self.user)
        }

        self.quetzalcoatl.store.chatDelegate = self
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
                    self.chats = self.quetzalcoatl.store.retrieveAllChats()

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
        // Group message test
        //        self.quetzalcoatl.sendGroupMessage("", type: .new, to: [self.testContact, self.otherContact, self.ellenContact, self.user.address])
        //        // 1:1 chat test.
        let chat = self.quetzalcoatl.store.fetchOrCreateChat(with: self.igorContact.name)
        self.didRequestSendMessage(text: "", in: chat)
    }
}

extension ChatsViewController: UITableViewDataSource {
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

extension ChatsViewController: SignalServiceStoreChatDelegate {
    func signalServiceStoreWillChangeChats() {
        self.tableView.beginUpdates()
    }

    func signalServiceStoreDidChangeChat(_ chat: SignalChat, at indexPath: IndexPath, for changeType: SignalServiceStore.ChangeType) {
        switch changeType {
        case .delete:
            self.chats.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        case .insert:
            self.chats.insert(chat, at: indexPath.row)
            self.tableView.insertRows(at: [indexPath], with: .right)
        case .update:
            self.chats.remove(at: indexPath.row)
            self.chats.insert(chat, at: indexPath.row)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }

    func signalServiceStoreDidChangeChats() {
        self.tableView.endUpdates()
    }
}

extension ChatsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = self.chats[indexPath.row]

        let destination = MessagesViewController(chat: chat)
        destination.delegate = self

        self.quetzalcoatl.store.messageDelegate = destination
        self.navigationController?.pushViewController(destination, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
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

class ContactManager {
    private static let shared = ContactManager()

    private let idClient: IDAPIClient

    init() {
        self.idClient = IDAPIClient()
    }

    static func displayName(for address: String) -> String {
        var name: String!

        let semaphore = DispatchSemaphore(value: 0)

        self.shared.idClient.findUserWithId(address) { profile in
            name = profile.nameOrUsername
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .distantFuture)

        return name
    }

    static func image(for address: String) -> UIImage? {
        if address == "0x94b7382e8cbd02fc7bfd2e233e42b778ac2ce224" {
            return UIImage(named: "igor2")
        } else if address == "0xcc4886677b6f60e346fe48968189c1b1fe9f3b33" {
            return UIImage(named: "karina")
        } else {
            return UIImage(named: "igor")
        }
    }
}
