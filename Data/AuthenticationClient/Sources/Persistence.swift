//
//  Persistence.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 28/12/2024.
//

import Foundation
import VLogging

protocol SecurityAccess {
    mutating func addItem(query: [String: Any]) -> OSStatus
    mutating func updateItem(query: [String: Any], attributes: [String: Any]) -> OSStatus
    mutating func deleteItem(query: [String: Any]) -> OSStatus
    func copyItem(query: [String: Any], result: UnsafeMutablePointer<CFTypeRef?>) -> OSStatus
}

struct KeychainAccess: SecurityAccess {

    func addItem(query: [String : Any]) -> OSStatus {
        SecItemAdd(query as CFDictionary, nil)
    }

    func updateItem(query: [String : Any], attributes: [String : Any]) -> OSStatus {
        SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    }

    func deleteItem(query: [String : Any]) -> OSStatus {
        SecItemDelete(query as CFDictionary)
    }

    func copyItem(query: [String : Any], result: UnsafeMutablePointer<CFTypeRef?>) -> OSStatus {
        SecItemCopyMatching(query as CFDictionary, result)
    }
}

enum PersistenceError: Error {
    case persistenceFailed
    case retrievalFailed
}

/// An abstraction for secure persistence of the authentication state.
protocol Persistence {
    func persist(state: Data) throws

    func retrieve() throws -> Data?

    func clear() throws
}

final class KeychainPersistence: Persistence {
    // MARK: Internal

    private var keychainAccess: SecurityAccess

    init(keychainAccess: SecurityAccess = KeychainAccess()) {
        self.keychainAccess = keychainAccess
    }

    func persist(state: Data) throws {
        let addquery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: itemKey,
            kSecValueData as String: state,
        ]
        let status = keychainAccess.addItem(query: addquery)
        if status == errSecDuplicateItem {
            logger.info("State already exists, updating")
            try update(state: state)
        } else if status != errSecSuccess {
            logger.error("Failed to persist state -- \(status) status")
            throw PersistenceError.persistenceFailed
        }
        logger.info("State persisted successfully")
    }

    func retrieve() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: itemKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        let status = keychainAccess.copyItem(query: query, result: &result)
        if status == errSecItemNotFound {
            logger.info("No state found")
            return nil
        } else if status != errSecSuccess {
            logger.error("Failed to retrieve state -- \(status) status")
            throw PersistenceError.retrievalFailed
        }
        guard let data = result as? Data else {
            logger.error("Invalid data type found")
            throw PersistenceError.retrievalFailed
        }

        return data
    }

    func clear() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: itemKey,
        ]

        let status = keychainAccess.deleteItem(query: query)
        if status != errSecSuccess && status != errSecItemNotFound {
            logger.error("Failed to clear state -- \(status) status")
            throw PersistenceError.persistenceFailed
        }
    }

    // MARK: Private

    private let itemKey = "com.quran.oauth.state"

    private func update(state: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: itemKey,
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: state,
        ]
        let status = keychainAccess.updateItem(query: query, attributes: attributes)
        if status != errSecSuccess {
            logger.error("Failed to update state -- \(status) status")
            throw PersistenceError.persistenceFailed
        }
        logger.info("State updated")
    }
}
