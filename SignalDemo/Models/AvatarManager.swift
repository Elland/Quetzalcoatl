//
//  AvatarManager.swift
//  Signal
//
//  Created by Igor Ranieri on 09.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import UIKit
import AwesomeCache

class AvatarManager {
    static let shared = AvatarManager()

    static let avatarDidUpdateNotification = Notification.Name("AvatarManager.avatarDidUpdateNotification")

    private var session = URLSession(configuration: .default)
    private let cache = try! Cache<UIImage>(name: "com.quetzalcoatl.AvatarCache")
    private let idClient = IDAPIClient()

    static func avatar(for id: String, at path: String?, _ completion: @escaping (_ avatar: UIImage?) -> Void) {
        guard let path = path,
            let url = URL(string: path) else {
                completion(nil)
                return
        }

        self.shared.cache.setObject(forKey: id, cacheBlock: { (success, failure) in
            let task = self.shared.session.dataTask(with: url) { (data, response, error) in
                if let data = data, let image = UIImage(data: data) {
                    success(image, .never)
                } else {
                    failure(nil)
                }
            }

            task.resume()
        }, completion: { (image, isFromCache, error) in
            DispatchQueue.main.async {
                completion(image)
            }
        })
    }

    static func cachedAvatar(for id: String) -> UIImage? {
        self.shared.idClient.findUserWithId(id) { profile in
            self.avatar(for: id, at: profile.avatar, { avatarImage in

                guard let avatarImage = avatarImage,
                    let cached = self.shared.cache[id],
                    cached != avatarImage else { return }

                self.shared.cache[id] = avatarImage

                NotificationCenter.default.post(name: self.avatarDidUpdateNotification, object: id, userInfo: ["image" : avatarImage])
            })
        }

        return self.shared.cache[id]
    }
}
