//
//  CGFloat+Quetzal.swift
//  Signal
//
//  Created by Igor Ranieri on 11.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import UIKit

public extension CGFloat {
    /// The height of a single pixel on the screen.
    static var lineHeight: CGFloat {
        return 1 / UIScreen.main.scale
    }
}
