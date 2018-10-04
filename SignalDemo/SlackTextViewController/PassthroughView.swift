//
//  PassthroughView.swift
//  Signal
//
//  Created by Igor Ranieri on 01.10.18.
//

import UIKit

@objc public class PassthroughView: UIView {
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)

        return view == self ? nil : view
    }
}

