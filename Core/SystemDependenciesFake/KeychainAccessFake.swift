//
//  KeychainAccessFake.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 21/01/2025.
//

import Foundation
import SystemDependencies

public class KeychainAccessFake: KeychainAccess {
    private var items: [String: [String: Any]] = [:]

    public init() { }

    public func addItem(query: [String: Any]) -> OSStatus {
        guard let key = query[kSecAttrAccount as String] as? String else {
            return errSecParam
        }
        items[key] = query
        return errSecSuccess
    }

    public func updateItem(query: [String: Any], attributes: [String: Any]) -> OSStatus {
        guard let key = query[kSecAttrAccount as String] as? String else {
            return errSecItemNotFound
        }
        items[key] = attributes
        return errSecSuccess
    }

    public func deleteItem(query: [String: Any]) -> OSStatus {
        guard let key = query[kSecAttrAccount as String] as? String else {
            return errSecParam
        }
        items[key] = nil
        return errSecSuccess
    }

    public func copyItem(query: [String: Any], result: UnsafeMutablePointer<CFTypeRef?>) -> OSStatus {
        guard let key = query[kSecAttrAccount as String] as? String else {
            return errSecItemNotFound
        }
        guard let item = items[key] else {
            return errSecItemNotFound
        }
        guard let value = item[kSecValueData as String] as? Data else {
            return errSecParam
        }
        result.pointee = value as CFData
        return errSecSuccess
    }
}
