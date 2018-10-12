//
//  AppDelegate.swift
//  SQLiteDemo
//
//  Created by Igor Ranieri on 20.04.18.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    static var shared: AppDelegate!

    var token: String = "" {
        didSet {
            self.updateRemoteNotificationCredentials()
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppDelegate.shared = self

        let window = UIWindow(frame: UIScreen.main.bounds)

        window.rootViewController = TabBarController()
        window.backgroundColor = .white
        window.tintColor = .tint
        window.makeKeyAndVisible()

        self.window = window

        SessionManager.shared.loadOrCreateuser()

        NotificationCenter.default.addObserver(forName: ChatsDataSource.chatDidUpdateNotification, object: nil, queue: .main) { n in
            UIApplication.shared.applicationIconBadgeNumber = (n.object as? Int) ?? 0
        }

        return true
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("oh no, could not register for remote notifications")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 20) {
            completionHandler(.newData)
        }

        SessionManager.shared.fetchContent()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NSLog("Did receive notification %@", notification)

        completionHandler([.badge, .alert, .sound])
//        BackgroundNotificationHandler.handle(notification) { options in
//            completionHandler(options)
//        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.token = deviceToken.hexadecimalString

        let center = UNUserNotificationCenter.current()

        let messageNotificationCategory = UNNotificationCategory(identifier: "messageNotificationCategory", actions: [], intentIdentifiers: [], options: [])
        center.setNotificationCategories([messageNotificationCategory])

        center.getNotificationSettings(completionHandler: {settings in
            print(settings)
        })
    }

    func updateRemoteNotificationCredentials() {
        SessionManager.shared.updatePushNotificationCredentials(self.token)
    }

    func requestAPNS() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, _) in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}
