//
//  Keychains.swift
//  Jgrammar
//
//  Created by Nguyen Van Dung on 12/11/16.
//  Copyright © 2016 Dht. All rights reserved.
//

import Foundation
import DhtKeychain

enum Keychains: String {
    case purchasedid = "purchasedid"
    case deviceId = "cplDeviceUdid"

    func set(value: Any?) {
        if let value = value {
            KeychainItemWrapper.save(self.rawValue, data: value)
        }
    }

    func get() -> Any? {
        return KeychainItemWrapper.load(self.rawValue)
    }

    func getStringOrEmpty() -> String {
        if let value = KeychainItemWrapper.load(self.rawValue) as? String {
            return value
        }
        return ""
    }

    static func getDeviceId() -> String {
        var dvId = Keychains.deviceId.getStringOrEmpty()
        if dvId.isEmpty {
            dvId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        }
        Keychains.deviceId.set(value: dvId)
        return dvId
    }
}
