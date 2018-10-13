//
//  ContactsManager.swift
//  Signal
//
//  Created by Igor Ranieri on 10.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import Quetzalcoatl
import AwesomeCache

class ContactManager {
    static let displayNameDidUpdateNotification = Notification.Name("AvatarManager.displayNameDidUpdateNotification")

    private(set) var profiles: [Profile] = []

    let persistenceStore: FilePersistenceStore

    var profilesAvatarPaths: [String] {
        return self.profiles.compactMap { $0.avatar }
    }

    var profilesIds: [String] {
        return self.profiles.map { $0.id }
    }

    init(persistenceStore: FilePersistenceStore) {
        self.persistenceStore = persistenceStore
        self.fetchContactsFromDatabase()
    }

    func profile(for id: String) -> Profile? {
        return self.profiles.first(where: {  $0.id == id })
    }

    func updateProfile(_ profile: Profile) {
        guard let existingProfileIndex = self.profiles.index(where: { $0.id == profile.id }) else {
            self.profiles.append(profile)

            return
        }

        self.profiles[existingProfileIndex] = profile
    }

    public func clearProfiles() {
        self.profiles = []
    }

    func fetchContactsFromDatabase() {
        self.profiles = self.persistenceStore.retrieveContacts()
    }
}

extension ContactManager: SignalRecipientsDisplayDelegate {
    func displayName(for address: String) -> String {
        guard let profile = self.profiles.first(where: { $0.id == address }) else { return address.truncated(limit: 6, leader: "") }

        return profile.nameOrDisplayName
    }

    func image(for address: String) -> UIImage? {
        return AvatarManager.cachedAvatar(for: address)
    }
}
