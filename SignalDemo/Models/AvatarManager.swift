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

    private var session = URLSession(configuration: .default)
    private let cache = try! Cache<UIImage>(name: "com.quetzalcoatl.AvatarCache")

    static func avatar(at path: String?, _ completion: @escaping (_ avatar: UIImage?) -> Void) {
        guard let path = path,
            let url = URL(string: path) else {
                completion(nil)
                return
        }

        self.shared.cache.setObject(forKey: url.absoluteString, cacheBlock: { (success, failure) in
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
}
