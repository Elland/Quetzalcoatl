//
//  NavigationController.swift
//  Signal
//
//  Created by Igor Ranieri on 02.10.18.
//

import UIKit

class ChatsNavigationController: ConnectionStatusDisplayingNavigationController {
    func openChat(with identifier: String, animated: Bool) {
        _ = self.popToRootViewController(animated: false)
        guard let chatsViewController = self.viewControllers.first as? ChatsViewController else { return }
        chatsViewController.openChat(with: identifier, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
