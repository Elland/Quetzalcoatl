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
    static let displayNameDidUpdateNotification = Notification.Name("ContactManager.displayNameDidUpdateNotification")
    static let didAddContactNotification = Notification.Name("ContactManager.didAddContactNotification")

    private(set) var profiles: [Profile] = []

    private let idClient = IDAPIClient()

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
        if let current = Profile.current,  current.id == address  {
            return current.nameOrDisplayName
        }

        if let profile = self.profiles.first(where: { $0.id == address }) {

            self.idClient.findUserWithId(address) { newProfile in
                guard let newProfile = newProfile, newProfile.name != profile.name else { return }
                self.persistenceStore.updateContact(newProfile)
                self.fetchContactsFromDatabase()

                NSLog("Updated contact %@", newProfile.nameOrUsername)

                NotificationCenter.default.post(name: ContactManager.displayNameDidUpdateNotification, object: newProfile)
            }

            return profile.nameOrDisplayName
        } else {
            self.idClient.findUserWithId(address) { newProfile in
                guard let newProfile = newProfile else { return }
                if self.persistenceStore.retrieveContacts().first(where: {$0.id == address}) != nil {
                    self.persistenceStore.updateContact(newProfile)
                } else {
                    self.persistenceStore.storeContact(newProfile)
                }
                self.fetchContactsFromDatabase()

                NSLog("Added contact %@", newProfile.nameOrUsername)

                NotificationCenter.default.post(name: ContactManager.displayNameDidUpdateNotification, object: newProfile)
            }

            return address.truncated(limit: 6, leader: "")
        }
    }

    func image(for address: String) -> UIImage? {
        return AvatarManager.cachedAvatar(for: address)
    }
}
