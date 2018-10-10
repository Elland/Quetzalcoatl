//
//  ContactsManager.swift
//  Signal
//
//  Created by Igor Ranieri on 10.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

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
