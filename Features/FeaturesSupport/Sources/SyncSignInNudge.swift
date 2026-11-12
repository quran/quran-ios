#if QURAN_SYNC
//
//  SyncSignInNudge.swift
//

import Analytics
import AuthenticationClient
import Foundation
import Localization
import NoorUI
import SwiftUI
import SystemDependencies
import UIKit
import VLogging

/// Reminds a signed-out user to sign in after they save a new note or collection:
/// twice at most, a week apart, and never again once they sign in, tap Sign In, or dismiss it.
@MainActor
public final class SyncSignInNudge {
    // MARK: Lifecycle

    /// - Parameter signInViewControllers: The screens to sign in from, preferred first, such as a sheet and
    ///   the screens under it. Read when a toast is made, before its screen can close, and held weakly;
    ///   Sign In uses the first still in a window.
    public init(
        authenticationClient: any AuthenticationClient,
        analytics: AnalyticsLibrary,
        time: SystemTime = DefaultSystemTime(),
        signInViewControllers: @escaping @MainActor () -> [UIViewController]
    ) {
        self.authenticationClient = authenticationClient
        self.analytics = analytics
        self.time = time
        self.signInViewControllers = signInViewControllers
    }

    // MARK: Public

    public enum Item {
        case note
        case collection
    }

    /// Stops the reminder for good, for a sign-in that didn't start from it, such as in Settings.
    public static func stopAfterSignIn() {
        SyncSignInNudgePreferences.shared.isStopped = true
    }

    /// The toast to show after a new `item` is saved, or `nil` when it shouldn't show. Returning one counts as a show.
    public func toast(after item: Item) async -> Toast? {
        guard canShow else {
            return nil
        }
        guard await authenticationClient.authenticationState != .authenticated else {
            Self.stopAfterSignIn()
            return nil
        }
        // Another save could have shown it while reading the state.
        guard canShow else {
            return nil
        }

        preferences.showCount += 1
        preferences.lastShownDate = time.now
        analytics.quranSyncSignInNudgeShown(from: item.analyticsSource)
        logger.info("Quran Sync: showing sign-in toast \(preferences.showCount) after saving \(item)")

        let presenters = signInViewControllers().map(WeakViewController.init)
        return Toast(
            .text(l(item.titleKey)),
            subtitle: .text(l("sync.nudge.subtitle")),
            icon: Toast.Icon(.checkmark),
            // The toast keeps the reminder alive, as its screen can close before the user taps.
            action: ToastAction(title: l("sync.nudge.sign-in")) { [self] in
                preferences.isStopped = true
                Task {
                    await signIn(after: item, from: presenters)
                }
            },
            onUserDismiss: { [self] in
                preferences.isStopped = true
                analytics.quranSyncSignInNudgeDismissed(from: item.analyticsSource)
            },
            duration: 6
        )
    }

    // MARK: Private

    private struct WeakViewController {
        weak var value: UIViewController?
    }

    private static let maximumShowCount = 2
    private static let minimumIntervalBetweenShows: TimeInterval = 7 * 24 * 60 * 60

    private let authenticationClient: any AuthenticationClient
    private let analytics: AnalyticsLibrary
    private let time: SystemTime
    private let signInViewControllers: @MainActor () -> [UIViewController]
    private let preferences = SyncSignInNudgePreferences.shared

    private var canShow: Bool {
        guard !preferences.isStopped else {
            return false
        }
        let showCount = preferences.showCount
        guard showCount < Self.maximumShowCount else {
            return false
        }
        guard showCount > 0, let lastShownDate = preferences.lastShownDate else {
            return true
        }
        return time.now.timeIntervalSince(lastShownDate) >= Self.minimumIntervalBetweenShows
    }

    /// The first screen still in a window.
    private static func presenter(among presenters: [WeakViewController]) -> UIViewController? {
        presenters.lazy.compactMap(\.value).first { $0.viewIfLoaded?.window != nil }
    }

    private func signIn(after item: Item, from presenters: [WeakViewController]) async {
        guard let viewController = Self.presenter(among: presenters) else {
            logger.error("Quran Sync: no screen to sign in from the sign-in toast")
            return
        }
        analytics.quranSyncSignIn(from: item.analyticsSource)
        logger.info("Quran Sync: starting sign in from the sign-in toast")
        do {
            try await authenticationClient.login(on: viewController)
            logger.info("Quran Sync: sign in completed from the sign-in toast")
        } catch AuthenticationClientError.cancelled {
            logger.info("Quran Sync: sign in cancelled from the sign-in toast")
        } catch {
            logger.error("Quran Sync: failed to sign in from the sign-in toast: \(error)")
            // The screen the sign-in started from can close meanwhile.
            Self.presenter(among: presenters)?.showErrorAlert(error: error)
        }
    }
}

private extension SyncSignInNudge.Item {
    var titleKey: String {
        switch self {
        case .note: "sync.nudge.note-saved"
        case .collection: "sync.nudge.collection-created"
        }
    }

    var analyticsSource: QuranSyncAuthenticationSource {
        switch self {
        case .note: .noteSavedToast
        case .collection: .collectionCreatedToast
        }
    }
}
#endif
