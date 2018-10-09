//
//  AppDelegate.swift
//  SQLiteDemo
//
//  Created by Igor Ranieri on 20.04.18.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)

        window.rootViewController = TabBarController()
        window.backgroundColor = .white
        window.tintColor = .tint
        window.makeKeyAndVisible()

        self.window = window

        return true
    }
}
