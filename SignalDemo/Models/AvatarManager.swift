//
//  AvatarManager.swift
//  Signal
//
//  Created by Igor Ranieri on 09.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import UIKit
//import AwesomeCache

class AvatarManager {
    static let shared = AvatarManager()

    private var session = URLSession(configuration: .default)

    static func avatar(at path: String?, _ completion: @escaping (_ avatar: UIImage?) -> Void) {
        guard let path = path,
            let url = URL(string: path) else {
                completion(nil)
                return
        }

        self.shared.session.dataTask(with: url) { (data, response, error) in
            var image: UIImage? = nil
            defer { completion(image) }

            guard let data = data, let img = UIImage(data: data) else { return }
            image = img
        }
    }
}
