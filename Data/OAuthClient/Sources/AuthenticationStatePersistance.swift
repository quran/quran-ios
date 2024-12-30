//
//  File.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 28/12/2024.
//

import Foundation
import VLogging

protocol AuthenticationStatePersistance {

    func persist(state: AuthenticationData) throws

    func retrieve() throws -> AuthenticationData?

    func clear() throws
}

final class KeychainAuthenticationStatePersistance: AuthenticationStatePersistance {

    private let itemKey = "com.quran.oauth.state"

    func persist(state: AuthenticationData) throws {
        let data = try JSONEncoder().encode(state)
        let addquery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: itemKey,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(addquery as CFDictionary, nil)
        if status != errSecSuccess {
            logger.error("Failed to persist state -- \(status) status")
            throw OAuthClientError.failedToPersistState
        }
        logger.info("State persisted successfully")
    }

    func retrieve() throws -> AuthenticationData? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: itemKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            logger.info("No state found")
            return nil
        } else if status != errSecSuccess {
            logger.error("Failed to retrieve state -- \(status) status")
            throw OAuthClientError.failedToRetrieveState
        }
        guard let data = result as? Data else {
            logger.error("Invalid data type found")
            throw OAuthClientError.failedToRetrieveState
        }
        let state = try JSONDecoder().decode(AuthenticationData.self, from: data)
        return state
    }

    func clear() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: itemKey,
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            logger.error("Failed to clear state -- \(status) status")
            // throw something?
        }
    }
}
