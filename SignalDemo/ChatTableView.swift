//
//  ReversedTableView.swift
//  Signal
//
//  Created by Igor Ranieri on 02.10.18.
//

import UIKit

class ChatTableView: UITableView {
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .white
        self.estimatedRowHeight = 64.0
        self.separatorStyle = .none
        self.keyboardDismissMode = .interactive
        self.contentInsetAdjustmentBehavior = .always
//        self.transform = self.transform.rotated(by: .pi)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
