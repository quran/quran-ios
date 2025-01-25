//
//  KeychainAccess.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 21/01/2025.
//

import Foundation

public protocol KeychainAccess {
    func addItem(query: [String: Any]) -> OSStatus
    func updateItem(query: [String: Any], attributes: [String: Any]) -> OSStatus
    func deleteItem(query: [String: Any]) -> OSStatus
    func copyItem(query: [String: Any], result: UnsafeMutablePointer<CFTypeRef?>) -> OSStatus
}

public struct DefaultKeychainAccess: KeychainAccess {
    public init() { }

    public func addItem(query: [String: Any]) -> OSStatus {
        SecItemAdd(query as CFDictionary, nil)
    }

    public func updateItem(query: [String: Any], attributes: [String: Any]) -> OSStatus {
        SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    }

    public func deleteItem(query: [String: Any]) -> OSStatus {
        SecItemDelete(query as CFDictionary)
    }

    public func copyItem(query: [String: Any], result: UnsafeMutablePointer<CFTypeRef?>) -> OSStatus {
        SecItemCopyMatching(query as CFDictionary, result)
    }
}
