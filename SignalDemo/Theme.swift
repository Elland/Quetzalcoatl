//
//  Theme.swift
//  Signal
//
//  Created by Igor Ranieri on 02.10.18.
//

import UIKit

extension UIColor {
    static var tint: UIColor {
        return #colorLiteral(red: 0.5162177086, green: 0.08007196337, blue: 0.6534827352, alpha: 1)
    }

    static var outgoingBubble: UIColor {
        return .tint
    }
    static var incomingBubble: UIColor {
        return UIColor.init(white: 0.95, alpha: 1.0)
    }

    static var defaultTextDark: UIColor {
        return .black
    }

    static var defaultTextLight: UIColor {
        return .white
    }

    static var lighterText: UIColor {
        return .gray
    }
}

extension UIFont {
    static func defaultFont(size: CGFloat) -> UIFont {
        return UIFont(name: "MalayalamSangamMN", size: size)!
    }

    static func boldFont(size: CGFloat) -> UIFont {
        return UIFont(name: "MalayalamSangamMN-Bold", size: size)!
    }
}
