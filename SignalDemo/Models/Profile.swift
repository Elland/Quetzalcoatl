//
//  Profile.swift
//  Quetzalcoatl
//
//  Created by Igor Ranieri on 04.10.18.
//

import Foundation
import EtherealCereal

struct Profile: Codable {
    static let didUpdateCurrentProfileNotification = NSNotification.Name("Profile.didUpdateCurrentProfileNotification")
    let id: String // eth address
    var username: String
    var name: String?
    var avatar: String?
    let description: String?

    var password: String!

    static var current: Profile? {
        didSet {
            NotificationCenter.default.post(name: self.didUpdateCurrentProfileNotification, object: nil)
        }
    }

    var cereal: EtherealCereal! // make it ! to cheat Codable constraints…

    enum CodingKeys: String, CodingKey {
        case
        name,
        username,
        id = "toshi_id",
        avatar,
        description
    }

    var hashValue: Int {
        return self.id.hashValue
    }

    var displayUsername: String {
        return "@\(self.username)"
    }

    var nameOrDisplayName: String {
        let nameOrEmpty = String.contentsOrEmpty(for: name)
        guard !nameOrEmpty.isEmpty else {

            return self.displayUsername
        }

        return nameOrEmpty
    }

    var nameOrUsername: String {
        return self.name ?? self.username
    }

    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }

    var data: Data? {
        return try? JSONEncoder().encode(self)
    }

    // TODO: implement user blocking asap
    var isBlocked: Bool {
        return false
    }

    init(password: String, privateKey: String, username: String? = nil, name: String? = nil, avatar: String? = nil, description: String? = nil) {
        let cereal = EtherealCereal(privateKey: privateKey)

        self.id = cereal.address
        self.username = username ?? cereal.address.truncated(limit: 6, leader: "")
        self.cereal = cereal
        self.password = password
        self.name = name
        self.avatar = avatar
        self.description = description
    }

    static func name(from username: String) -> String {
        guard username.hasPrefix("@") else {
            // Does not need to be cleaned up
            return username
        }

        let index = username.index(username.startIndex, offsetBy: 1)
        return String(username[index...])
    }
}

extension Profile: Hashable {

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        return lhs.id == rhs.id
    }
}
