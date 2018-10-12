//
//  SessionManager.swift
//  Signal
//
//  Created by Igor Ranieri on 10.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import Quetzalcoatl
import EtherealCereal
import Teapot
import UserNotifications

class SessionManager {
    static var shared: SessionManager = SessionManager()

    private var fetcherJob: MessageFetcherJob?

    var user: Profile {
        return Profile.current!
    }

    let idClient = IDAPIClient()

    var currentChatId: String?

    var persistenceStore = FilePersistenceStore()

    var signalRecipientsDelegate = SignalRecipientsDisplayManager()

    var chatDelegate: SignalServiceStoreChatDelegate? {
        didSet {
            if let cd = self.chatDelegate {
                self.quetzalcoatl.store.chatDelegates.append(cd)
            }
        }
    }

    var messageDelegate: SignalServiceStoreMessageDelegate? {
        didSet {
            if let md = self.messageDelegate {
                self.quetzalcoatl.store.messageDelegates.append(md)
            }
        }
    }

    let teapot = Teapot(baseURL: URL(string: "https://quetzalcoatl-chat-service.herokuapp.com")!)

    lazy var quetzalcoatl: Quetzalcoatl = {
        return Quetzalcoatl(baseURL: self.teapot.baseURL, recipientsDelegate: self.signalRecipientsDelegate, persistenceStore: self.persistenceStore)
    }()

    init() {
        NotificationCenter.default.addObserver(forName: Profile.didUpdateCurrentProfileNotification, object: nil, queue: .main) { _ in
            guard let profile = Profile.current else { return }

            self.persistenceStore.storeUser(profile)
        }

        self.quetzalcoatl.store.messageDelegates.append(self)
    }

    func loadOrCreateuser() {
        if let user = self.persistenceStore.retrieveUser() {
            Profile.current = user

            self.quetzalcoatl.startSocket()
            self.quetzalcoatl.shouldKeepSocketAlive = true

            self.requestAPNS()

            return
        }

        self.idClient.registerUser(with: EtherealCereal()) { status in
            if status == .registered {
                guard let user = Profile.current else { return }

                self.idClient.fetchTimestamp { timestamp in
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

                            self.quetzalcoatl.startSocket()
                            self.quetzalcoatl.shouldKeepSocketAlive = true
                            self.persistenceStore.storeUser(user)

                            self.requestAPNS()
                        case .failure(_, _, let error):
                            NSLog(error.localizedDescription)
                            break
                        }
                    }
                }
            }
        }
    }

    func fetchContent() {
        self.fetcherJob = MessageFetcherJob(teapot: self.teapot, username: self.user.id, password: self.user.password, messageManager: self.quetzalcoatl.messageManager!)
        self.fetcherJob?.run()
    }

    func requestAPNS() {
        AppDelegate.shared.requestAPNS()
    }

    func updatePushNotificationCredentials(_ token: String) {
        self.idClient.fetchTimestamp { timestamp in
            let path = "/v1/accounts/apn"
            let payload = ["apnRegistrationId": token]

            let headers = self.teapot.basicAuthenticationHeader(username: self.user.id, password: self.user.password)

            self.teapot.put(path, parameters: RequestParameter(payload), headerFields: headers) { result in
                print(result)
            }
        }
    }
}

extension SessionManager: SignalServiceStoreMessageDelegate {
    func signalServiceStoreWillChangeMessages() {

    }

    func signalServiceStoreDidChangeMessage(_ message: SignalMessage, at indexPath: IndexPath, for changeType: SignalServiceStore.ChangeType) {
        if changeType == .insert {
            guard message.senderId != self.user.id else { return }
            guard let chat = self.quetzalcoatl.store.chat(chatId: message.chatId),
            chat.uniqueId != self.currentChatId
            else { return }

            
            let content = UNMutableNotificationContent()
            content.title = chat.displayName
            content.body = message.body
            content.threadIdentifier = chat.uniqueId
            content.sound = UNNotificationSound(named: UNNotificationSoundName("PN.m4a"))

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: message.uniqueId, content: content, trigger: trigger)

            let center = UNUserNotificationCenter.current()
            center.add(request, withCompletionHandler: nil)
        }
    }

    func signalServiceStoreDidChangeMessages() {

    }
}

struct SignalRecipientsDisplayManager: SignalRecipientsDisplayDelegate {
    func displayName(for address: String) -> String {
        return ContactManager.displayName(for: address)
    }

    func image(for address: String) -> UIImage? {
        return ContactManager.image(for: address)
    }
}

