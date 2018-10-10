//
//  AvatarImageView.swift
//  Signal
//
//  Created by Igor Ranieri on 10.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

class AvatarImageView: UIImageView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setup()
    }

    override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)

        self.setup()
    }

    override init(image: UIImage?) {
        super.init(image: image)

        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.setup()
    }

    private func setup() {
        self.clipsToBounds = true
        self.contentMode = .scaleAspectFill
        self.layer.borderColor = UIColor.black.withAlphaComponent(0.15).cgColor
        self.layer.borderWidth = .lineHeight
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.width / 2
    }
}
