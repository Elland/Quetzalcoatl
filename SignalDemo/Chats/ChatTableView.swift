//
//  ReversedTableView.swift
//  Signal
//
//  Created by Igor Ranieri on 02.10.18.
//

import UIKit

class ChatTableView: UITableView {

//    override var contentOffset: CGPoint {
//        didSet {
//            print("did set: \(self.contentOffset)")
//        }
//    }

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .white
        self.estimatedRowHeight = 64.0
        self.separatorStyle = .none
        self.keyboardDismissMode = .interactive
        self.contentInsetAdjustmentBehavior = .never
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
