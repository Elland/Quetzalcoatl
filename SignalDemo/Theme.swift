//
//  Theme.swift
//  Signal
//
//  Created by Igor Ranieri on 02.10.18.
//

import UIKit

extension UIColor {
    static var tint: UIColor {
        return #colorLiteral(red: 0.4320931733, green: 0.262832582, blue: 0.9611081481, alpha: 1)
    }

    static var outgoingBubble: UIColor {
        return #colorLiteral(red: 0.4320931733, green: 0.262832582, blue: 0.9611081481, alpha: 1)
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
}

extension UIFont {
    static func defaultFont(size: CGFloat) -> UIFont {
        return UIFont(name: "MalayalamSangamMN", size: size)!
    }
}
