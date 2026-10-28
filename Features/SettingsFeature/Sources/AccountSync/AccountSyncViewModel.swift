#if QURAN_SYNC
//
//  AccountSyncViewModel.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import AuthenticationClient
import Foundation
import MobileSync
import SafariServices
import UIKit
import VLogging

@MainActor
final class AccountSyncViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        user: MobileSyncUser?,
        authenticationClient: any AuthenticationClient,
        quranDataService: MobileSyncDataService,
        quranProfileURL: URL,
        signOut: @escaping @MainActor () async throws -> Void,
        navigationController: UINavigationController?
    ) {
        self.user = user
        self.authenticationClient = authenticationClient
        self.quranDataService = quranDataService
        self.quranProfileURL = quranProfileURL
        self.signOut = signOut
        self.navigationController = navigationController
    }

    // MARK: Internal

    /// How many held items and runs the screen shows before linking to the full list.
    static let previewCount = 3

    @Published private(set) var user: MobileSyncUser?
    @Published private(set) var activity = SyncActivity()
    @Published private(set) var lookup = HeldItemLookup()
    @Published var isSignOutConfirmationPresented = false
    @Published var error: Error?

    var status: SyncStatusSummary {
        SyncStatusSummary(activity)
    }

    var heldRows: [HeldItemRow] {
        HeldItemRow.rows(for: activity.heldItems, lookup: lookup)
    }

    var recentRuns: [SyncRunRow] {
        activity.runs.prefix(Self.previewCount).map { SyncRunRow($0) }
    }

    /// Follows the signed-in user and the sync activity until the task is cancelled.
    func start() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeUser() }
            group.addTask { await self.observeActivity() }
            group.addTask { await self.observeLookup() }
        }
    }

    func syncNow() {
        logger.info("Quran Sync: Sync now from Account & Sync")
        quranDataService.triggerSync(immediately: true)
    }

    func openQuranComProfile() {
        logger.info("Account & Sync: Open Quran.com profile.")
        let viewController = SFSafariViewController(url: quranProfileURL)
        navigationController?.present(viewController, animated: true)
    }

    func requestSignOut() {
        logger.info("Quran Sync: requested sign out confirmation from Account & Sync")
        isSignOutConfirmationPresented = true
    }

    func signOutOfQuranCom() async {
        do {
            try await signOut()
            leave()
        } catch {
            self.error = error
        }
    }

    // MARK: Private

    private let authenticationClient: any AuthenticationClient
    private let quranDataService: MobileSyncDataService
    private let quranProfileURL: URL
    private let signOut: @MainActor () async throws -> Void
    private weak var navigationController: UINavigationController?

    private func observeUser() async {
        do {
            for try await user in authenticationClient.loggedInUserUpdates {
                // A nil user is also a signed-in session whose profile isn't known yet.
                guard await authenticationClient.authenticationState == .authenticated else {
                    leave()
                    return
                }
                if let user {
                    self.user = user
                }
            }
        } catch is CancellationError {
            return
        } catch {
            logger.error("Quran Sync: failed to observe the signed-in user from Account & Sync: \(error)")
        }
    }

    private func observeActivity() async {
        for await change in SyncActivity.changes(of: quranDataService) {
            activity.apply(change)
        }
    }

    private func observeLookup() async {
        for await change in HeldItemLookup.changes(of: quranDataService) {
            lookup.apply(change)
        }
    }

    /// Returns to Settings, which shows the signed-out card.
    private func leave() {
        guard let navigationController, let settings = navigationController.viewControllers.first else {
            return
        }
        navigationController.popToViewController(settings, animated: navigationController.view.window != nil)
    }
}
#endif
