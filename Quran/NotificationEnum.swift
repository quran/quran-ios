//
//  NotificationEnum.swift
//  RapidSave
//
//  Created by Nguyen Van Dung on 5/2/17.
//  Copyright © 2017 Dht. All rights reserved.
//

import Foundation

enum NotificationName: String {
    case networkStateChange = "KNotificationNetworkStateDidChange"
    case kNotificationDidPurchase = "kNotification_did_purchase"
    case kNotificationFullAds = "kNotificationFullAds"

    public func name() -> NSNotification.Name {
        return Notification.Name(rawValue: self.rawValue)
    }
}
