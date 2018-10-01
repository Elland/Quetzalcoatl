//
//  AppDelegate.swift
//  SQLiteDemo
//
//  Created by Igor Ranieri on 20.04.18.
//  Copyright © 2018 Bakken&Bæck. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)

        window.rootViewController = UINavigationController(rootViewController: ChatsViewController(nibName: nil, bundle: nil))
        window.backgroundColor = .white
        window.makeKeyAndVisible()

        self.window = window

        return true
    }
}
