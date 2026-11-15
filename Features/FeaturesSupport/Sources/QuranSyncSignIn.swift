#if QURAN_SYNC
//
//  QuranSyncSignIn.swift
//

import Analytics
import AuthenticationClient
import UIKit
import VLogging

/// Starts the Quran.com sign-in for every screen that offers it, so each logs it the same way
/// and any sign-in retires the sign-in reminder.
@MainActor
public enum QuranSyncSignIn {
    /// Signs in to Quran.com from `viewController`.
    /// - Returns: The state after signing in, or `nil` when the user cancelled.
    /// - Throws: Any other failure, for the caller to show.
    @discardableResult
    public static func signIn(
        on viewController: UIViewController,
        authenticationClient: any AuthenticationClient,
        analytics: AnalyticsLibrary,
        source: QuranSyncAuthenticationSource
    ) async throws(AuthenticationClientError) -> AuthenticationState? {
        analytics.quranSyncSignIn(from: source)
        logger.info("Quran Sync: starting sign in from \(source.rawValue)")
        do {
            try await authenticationClient.login(on: viewController)
        } catch .cancelled {
            logger.info("Quran Sync: sign in cancelled from \(source.rawValue)")
            return nil
        } catch {
            logger.error("Quran Sync: failed to sign in from \(source.rawValue): \(error)")
            throw error
        }
        let state = await authenticationClient.authenticationState
        logger.info("Quran Sync: sign in completed from \(source.rawValue). State: \(state)")
        if state == .authenticated {
            SyncSignInNudge.stopAfterSignIn()
        }
        return state
    }
}
#endif
