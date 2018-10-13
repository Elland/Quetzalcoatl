//
//  MessageErrorView.swift
//  Signal
//
//  Created by Igor Ranieri on 13.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import UIKit

final class MessagesErrorView: UIControl {
    private lazy var imageView: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.image = UIImage(named: "error")!
        view.contentMode = .scaleAspectFit

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.imageView)
        self.clipsToBounds = true  

        self.imageView.set(height: 24)
        self.imageView.set(width: 24)
        self.imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0).isActive = true
        self.imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
