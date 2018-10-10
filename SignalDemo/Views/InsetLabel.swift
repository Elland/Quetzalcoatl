//
//  InsetLabel.swift
//  Imgur
//
//  Created by Igor Ranieri on 06.10.18.
//  Copyright © 2018 EXC_BAD_ACCESS. All rights reserved.
//

import UIKit

class InsetLabel: UILabel {
    @IBInspectable var insets: UIEdgeInsets = .zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: self.insets))
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var adjustedSize = super.sizeThatFits(size)
        adjustedSize.width += self.insets.left + self.insets.right
        adjustedSize.height += self.insets.top + self.insets.bottom

        return adjustedSize
    }

    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.width += self.insets.left + self.insets.right
        contentSize.height += self.insets.top + self.insets.bottom

        return contentSize
    }
}
