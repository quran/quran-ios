//
//  Persistence.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 28/12/2024.
//

import Foundation
import VLogging

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
    private let itemKey = "com.quran.oauth.state"

    func persist(state: Data) throws {
        let addquery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: itemKey,
            kSecValueData as String: state,
        ]
        let status = SecItemAdd(addquery as CFDictionary, nil)
        if status != errSecSuccess {
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
        let status = SecItemCopyMatching(query as CFDictionary, &result)
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

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            logger.error("Failed to clear state -- \(status) status")
            throw PersistenceError.persistenceFailed
        }
    }
}
