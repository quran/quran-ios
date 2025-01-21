//
//  Persistence.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 28/12/2024.
//

import Foundation
import VLogging
import SystemDependencies

public enum PersistenceError: Error {
    case persistenceFailed
    case retrievalFailed
}

/// An abstraction for secure persistence of data.
///
/// Currently, only supports `Data` as the data type of the saved objects.
public protocol SecurePersistence {
    func set(data: Data, forKey key: String) throws

    func getData(forKey key: String) throws -> Data?

    func clearData(forKey key: String) throws
}

public final class KeychainPersistence: SecurePersistence {
    // MARK: Internal

    private var keychainAccess: KeychainAccess

    public init(keychainAccess: KeychainAccess = DefaultKeychainAccess()) {
        self.keychainAccess = keychainAccess
    }

    public func set(data: Data, forKey key: String) throws {
        let addquery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        let status = keychainAccess.addItem(query: addquery)
        if status == errSecDuplicateItem {
            logger.info("[KeychainPersistence] Data already exists, updating")
            try update(dat: data, forKey: key)
        } else if status != errSecSuccess {
            logger.error("[KeychainPersistence] Failed to persist data -- \(status) status")
            throw PersistenceError.persistenceFailed
        }
        logger.info("[KeychainPersistence] Data persisted successfully")
    }

    public func getData(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        let status = keychainAccess.copyItem(query: query, result: &result)
        if status == errSecItemNotFound {
            logger.info("[KeychainPersistence] No data found")
            return nil
        } else if status != errSecSuccess {
            logger.error("[KeychainPersistence] Failed to retrieve data -- \(status) status")
            throw PersistenceError.retrievalFailed
        }
        guard let data = result as? Data else {
            logger.error("[KeychainPersistence] Invalid data type found")
            throw PersistenceError.retrievalFailed
        }

        return data
    }

    public func clearData(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]

        let status = keychainAccess.deleteItem(query: query)
        if status != errSecSuccess && status != errSecItemNotFound {
            logger.error("[KeychainPersistence] Failed to clear data -- \(status) status")
            throw PersistenceError.persistenceFailed
        }
    }

    // MARK: Private

    private func update(dat: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: dat,
        ]
        let status = keychainAccess.updateItem(query: query, attributes: attributes)
        if status != errSecSuccess {
            logger.error("[KeychainPersistence] Failed to update data -- \(status) status")
            throw PersistenceError.persistenceFailed
        }
        logger.info("[KeychainPersistence] Data updated")
    }
}
