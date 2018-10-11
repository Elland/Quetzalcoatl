//
//  ConnectionStatusViewController.swift
//  Signal
//
//  Created by Igor Ranieri on 11.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import UIKit
import Quetzalcoatl

class ConnectionStatusDisplayingNavigationController: UINavigationController, SignalSocketConnectionStatusDelegate {
    private lazy var connectionStatusView: UIView = {
        let view = UIView()

        view.backgroundColor = #colorLiteral(red: 0.7310634255, green: 0.1997378469, blue: 0.1849039495, alpha: 1)

        let label = UILabel()
        label.textColor = .white
        label.font = .boldFont(size: 14)
        label.textAlignment = .center

        label.text = "Connection failed"

        view.addSubview(label)
        label.edgesToSuperview()

        view.set(height: 32)

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.connectionStatusView)
        self.connectionStatusView.topAnchor.constraint(equalTo: self.navigationBar.bottomAnchor).isActive = true
        self.connectionStatusView.leftToSuperview()
        self.connectionStatusView.rightToSuperview()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        SessionManager.shared.quetzalcoatl.connectionStatusDelegate = self
    }

    func socketConnectionStatusDidChange(_ isConnected: Bool) {
        self.connectionStatusView.isHidden = isConnected
    }
}
