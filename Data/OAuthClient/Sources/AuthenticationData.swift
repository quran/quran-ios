//
//  AuthenticationData.swift
//  QuranEngine
//
//  Created by Mohannad Hassan on 27/12/2024.
//

import AppAuth
import Combine
import Foundation
import VLogging

enum AuthenticationStateError: Error {
    case failedToRefreshTokens(Error?)
    case decodingError(Error?)
}

class AuthenticationData: NSObject, Codable {
    var stateChangedPublisher: AnyPublisher<Void, Never> { fatalError() }

    var isAuthorized: Bool {
        fatalError()
    }

    func getFreshTokens() async throws -> String {
        fatalError()
    }

    override init() { }

    required init(from decoder: any Decoder) throws {
        fatalError()
    }
}

class AppAuthAuthenticationData: AuthenticationData {
    private enum CodingKeys: String, CodingKey {
        case state
    }

    private let stateChangedSubject: PassthroughSubject<Void, Never> = .init()
    override var stateChangedPublisher: AnyPublisher<Void, Never> {
        stateChangedSubject.eraseToAnyPublisher()
    }

    private var state: OIDAuthState {
        didSet {
            stateChangedSubject.send()
        }
    }

    override var isAuthorized: Bool {
        state.isAuthorized
    }

    init(state: OIDAuthState) {
        self.state = state
        super.init()
        state.stateChangeDelegate = self
    }

    required init(from decoder: any Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let data = try container.decode(Data.self, forKey: .state)
            guard let state = try NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data) else {
                logger.error("Failed to decode OIDAuthState: Failed to unarchive data")
                throw AuthenticationStateError.decodingError(nil)
            }
            self.state = state
        } catch {
            logger.error("Failed to decode OIDAuthState: \(error)")
            throw AuthenticationStateError.decodingError(error)
        }
        super.init()
        state.stateChangeDelegate = self
    }

    override func encode(to encoder: any Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        let data = try NSKeyedArchiver.archivedData(withRootObject: state, requiringSecureCoding: true)
        try container.encode(data, forKey: .state)
    }

    override func getFreshTokens() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            state.performAction { accessToken, clientID, error in
                guard error == nil else {
                    logger.error("Failed to refresh tokens: \(error!)")
                    continuation.resume(throwing: AuthenticationStateError.failedToRefreshTokens(error))
                    return
                }
                guard let accessToken else {
                    logger.error("Failed to refresh tokens: No access token returned. An unexpected situation.")
                    continuation.resume(throwing: AuthenticationStateError.failedToRefreshTokens(nil))
                    return
                }
                continuation.resume(returning: accessToken)
            }
        }
    }
}

extension AppAuthAuthenticationData: OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        logger.info("OIDAuthState changed")
        stateChangedSubject.send()
    }
}
