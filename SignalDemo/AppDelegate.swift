//
//  AppDelegate.swift
//  SQLiteDemo
//
//  Created by Igor Ranieri on 20.04.18.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)

        SessionManager.shared.loadOrCreateuser()

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.badge]) { (granted, _) in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }

        UIApplication.shared.registerForRemoteNotifications()

        NotificationCenter.default.addObserver(forName: ChatsDataSource.chatDidUpdateNotification, object: nil, queue: .main) { n in
            UIApplication.shared.applicationIconBadgeNumber = (n.object as? Int) ?? 0
        }

        window.rootViewController = TabBarController()
        window.backgroundColor = .white
        window.tintColor = .tint
        window.makeKeyAndVisible()

        self.window = window

        return true
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("oh no, could not register for remote notifications")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("how remote notification?")
    }
}
