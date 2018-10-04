//
//  TabBarController.swift
//  SignalServiceSwift
//
//  Created by Igor Ranieri on 04.10.18.
//

import UIKit

private let TabBarItemTitleOffset: CGFloat = -3.0

class TabBarController: UITabBarController {
    
    lazy var chatsController: ChatsViewController = {
       return ChatsViewController(nibName: nil, bundle: nil)
    }()

    lazy var settingsNavController: SettingsNavigationController = {
        return SettingsNavigationController(rootViewController: UIViewController())
    }()

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.settingsNavController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settings")!, tag: 0)
        self.settingsNavController.tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset

        self.chatsController.tabBarItem = UITabBarItem(title: "Messages",image: UIImage(named: "messages")!, tag: 0)
        self.chatsController.tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset

        self.viewControllers = [self.chatsController, self.settingsNavController]
    }
}
