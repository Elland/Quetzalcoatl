//
//  BackgroundNotificationHandler.swift
//  Signal
//
//  Created by Igor Ranieri on 12.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import UIKit
import UserNotifications

class BackgroundNotificationHandler: NSObject {
    static func handle(_ notification: UNNotification, _ completion: @escaping ((_ options: UNNotificationPresentationOptions) -> Void)) {
        self.enqueueLocalNotification(body: notification.request.content.body, title: notification.request.content.title)

        completion([.badge, .alert, .sound])
    }

    static func enqueueLocalNotification(body: String, title: String) {
        let content = UNMutableNotificationContent()
        content.title = title

        content.body = body

        content.sound = UNNotificationSound(named: UNNotificationSoundName("PN.m4a"))

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: content.title, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: nil)
    }
}
