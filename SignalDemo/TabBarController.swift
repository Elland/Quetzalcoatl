//
//  TabBarController.swift
//  Quetzalcoatl
//
//  Created by Igor Ranieri on 04.10.18.
//

import UIKit

private let TabBarItemTitleOffset: CGFloat = -3.0

class TabBarController: UITabBarController {
    enum Tab: Int {
        case chats
        case settings
    }

    lazy var chatsNavigationController: ChatsNavigationController = {
        return ChatsNavigationController(rootViewController: ChatsViewController())
    }()

    lazy var settingsNavController: SettingsNavigationController = {
        return SettingsNavigationController(rootViewController: SettingsViewController.instantiate())
    }()

    convenience init() {
        self.init(nibName: nil, bundle: nil)

        self.settingsNavController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settings")!, tag: 0)
        self.settingsNavController.tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset

        self.chatsNavigationController.tabBarItem = UITabBarItem(title: "Messages",image: UIImage(named: "messages")!, tag: 0)
        self.chatsNavigationController.tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset

        self.viewControllers = [self.chatsNavigationController, self.settingsNavController]
    }

    func `switch`(to tab: Tab) {
        self.selectedIndex = tab.rawValue
    }
}
