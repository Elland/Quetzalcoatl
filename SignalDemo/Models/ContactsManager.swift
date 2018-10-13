//
//  ContactsManager.swift
//  Signal
//
//  Created by Igor Ranieri on 10.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import Quetzalcoatl
import AwesomeCache

class ContactManager: SignalRecipientsDisplayDelegate {
    static let shared = ContactManager()
    static let displayNameDidUpdateNotification = Notification.Name("AvatarManager.displayNameDidUpdateNotification")
    private let cache = try! Cache<NSString>(name: "com.quetzalcoatl.DisplayNameCache")
    private let idClient: IDAPIClient
    
    init() {
        self.idClient = IDAPIClient()
    }

    static func displayName(for address: String) -> String {
        return self.shared.displayName(for: address)
    }

    static func image(for address: String) -> UIImage? {
        return self.shared.image(for: address)
    }

    func displayName(for address: String) -> String {
        self.idClient.findUserWithId(address) { profile in
            guard let name = profile?.nameOrDisplayName else { return }

            self.cache[address] = name as NSString

            NotificationCenter.default.post(name: ContactManager.displayNameDidUpdateNotification, object: address, userInfo: ["displayName" : name])
        }

        return (self.cache[address] as String?) ?? address.truncated(limit: 6, leader: "")
    }

    func image(for address: String) -> UIImage? {
        return AvatarManager.cachedAvatar(for: address)
    }
}

