//
//  TabBarController.swift
//  Quetzalcoatl
//
//  Created by Igor Ranieri on 04.10.18.
//

import UIKit
import QuartzCore

private let TabBarItemTitleOffset: CGFloat = 5.0

class TabBarController: UITabBarController {
    enum Tab: Int {
        case contacts
        case chats
        case settings
    }

    lazy var contactsNavigationController: UINavigationController = {
        return UINavigationController(rootViewController: ContactsListViewController(createChat: false))
    }()


    lazy var chatsNavigationController: ChatsNavigationController = {
        return ChatsNavigationController(rootViewController: ChatsViewController())
    }()

    lazy var settingsNavController: SettingsNavigationController = {
        return SettingsNavigationController(rootViewController: SettingsViewController.instantiate())
    }()

    convenience init() {
        self.init(nibName: nil, bundle: nil)

        func configure(_ nav: UINavigationController) {
            nav.tabBarItem.imageInsets.top = TabBarItemTitleOffset
            nav.tabBarItem.imageInsets.bottom = -TabBarItemTitleOffset
            nav.navigationBar.prefersLargeTitles = true
        }

        self.contactsNavigationController.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "contacts")!, tag: 0)
        configure(self.contactsNavigationController)

        self.settingsNavController.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "settings")!, tag: 0)
        configure(self.settingsNavController)

        self.chatsNavigationController.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "messages")!, tag: 0)
        configure(self.chatsNavigationController)

        self.viewControllers = [
            self.contactsNavigationController,
            self.chatsNavigationController,
            self.settingsNavController
        ]

        self.tabBar.layer.cornerRadius = 20
        self.tabBar.layer.borderColor = UIColor.gray.cgColor
        self.tabBar.layer.borderWidth = .lineHeight
        self.tabBar.clipsToBounds = true
        self.switch(to: .chats)
    }

    func `switch`(to tab: Tab) {
        self.selectedIndex = tab.rawValue
    }
}
