//
//  NavigationBarRounding.swift
//  Signal
//
//  Created by Igor Ranieri on 13.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import Foundation

protocol NavigationBarRounding {
    var navigationBar: UINavigationBar { get }

    func addNavigationBarRounding()
}

extension NavigationBarRounding {
    func addNavigationBarRounding() {
        let navBar = self.navigationBar

        let navLayer = navBar.layer

        //Round
        var bounds = navLayer.bounds.insetBy(dx: 0, dy: -40)
        bounds.size.height += 1
        let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.bottomRight, .bottomLeft], cornerRadii: CGSize(width: 20.0, height: 20.0)).cgPath

        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = maskPath

        let borderLayer = CAShapeLayer()
        borderLayer.path = maskPath
        borderLayer.lineWidth = .lineHeight
        borderLayer.strokeColor = UIColor.black.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.frame = bounds

        navLayer.mask = maskLayer
        navLayer.addSublayer(borderLayer)
    }
}
