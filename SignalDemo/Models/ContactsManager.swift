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

        // TODO: unflatten this, use notifications instead 🤦🏽‍♀️
        self.shared.idClient.findUserWithId(address) { profile in
            name = profile.nameOrUsername
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .distantFuture)

        return name
    }

    static func image(for address: String) -> UIImage? {
        return AvatarManager.cachedAvatar(for: address)
    }
}
