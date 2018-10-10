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

class SessionManager {
    static var shared: SessionManager = SessionManager()

    var user: Profile {
        return Profile.current!
    }

    let idClient = IDAPIClient()

    var persistenceStore = FilePersistenceStore()

    var signalRecipientsDelegate = SignalRecipientsDisplayManager()
    var chatDelegate: SignalServiceStoreChatDelegate!

    let teapot = Teapot(baseURL: URL(string: "https://token-chat-service-development.herokuapp.com")!)

    lazy var quetzalcoatl: Quetzalcoatl = {
        let quetzalcoatl = Quetzalcoatl(baseURL: self.teapot.baseURL, recipientsDelegate: self.signalRecipientsDelegate, persistenceStore: self.persistenceStore)
        quetzalcoatl.store.chatDelegate = self.chatDelegate

        return quetzalcoatl
    }()

    init() {
        NotificationCenter.default.addObserver(forName: Profile.didUpdateCurrentProfileNotification, object: nil, queue: .main) { _ in
            guard let profile = Profile.current else { return }

            self.persistenceStore.storeUser(profile)
        }
    }

    func loadOrCreateuser() {
        if let user = self.persistenceStore.retrieveUser() {
            Profile.current = user

            self.quetzalcoatl.startSocket()
            self.quetzalcoatl.shouldKeepSocketAlive = true

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
                        case .failure(_, _, let error):
                            NSLog(error.localizedDescription)
                            break
                        }
                    }
                }
            }
        }
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
