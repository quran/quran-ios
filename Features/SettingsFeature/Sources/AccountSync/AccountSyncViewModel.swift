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
final class AccountSyncViewModel: NSObject, ObservableObject {
    // MARK: Lifecycle

    init(
        user: MobileSyncUser?,
        authenticationClient: any AuthenticationClient,
        quranDataService: MobileSyncDataService,
        quranProfileURL: URL,
        syncActivityBuilder: SyncActivityBuilder,
        editor: HeldItemEditor,
        signOut: @escaping @MainActor () async throws -> Void,
        navigationController: UINavigationController?
    ) {
        self.user = user
        self.authenticationClient = authenticationClient
        self.quranDataService = quranDataService
        self.quranProfileURL = quranProfileURL
        self.syncActivityBuilder = syncActivityBuilder
        self.editor = editor
        self.signOut = signOut
        self.navigationController = navigationController
        super.init()
    }

    // MARK: Internal

    /// How many held items and runs the screen shows before linking to the full list.
    static let previewCount = 3

    /// Fixes the held items.
    let editor: HeldItemEditor

    @Published private(set) var user: MobileSyncUser?
    @Published private(set) var activity = SyncActivity()
    @Published private(set) var lookup = HeldItemLookup()
    @Published var isSignOutConfirmationPresented = false
    /// The items that hadn't synced when sign-out was requested, or `nil` when they couldn't be read.
    @Published private(set) var unsyncedItems: MobileSyncUnsyncedItemCounts?
    /// Set to scroll to the items that don't sync; the view clears it once it has.
    @Published var scrollsToHeldItems = false
    @Published var error: Error?

    /// The profile fetch the Manage account sheet's closing started, if any.
    private(set) var profileRefresh: Task<Void, Never>?

    var status: SyncStatusSummary {
        SyncStatusSummary(activity)
    }

    var signOutWarning: SignOutWarning {
        SignOutWarning(unsynced: unsyncedItems, activity: activity)
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

    /// Opens every held item and every recent sync.
    func showActivity() {
        logger.info("Account & Sync: show Sync activity")
        navigationController?.pushViewController(
            syncActivityBuilder.build(navigationController: navigationController),
            animated: true
        )
    }

    func openQuranComProfile() {
        logger.info("Account & Sync: Open Quran.com profile.")
        let viewController = SFSafariViewController(url: quranProfileURL)
        viewController.delegate = self
        navigationController?.present(viewController, animated: true)
    }

    /// Asks the user to confirm, warning about the changes that haven't synced, which sign-out deletes.
    func requestSignOut() async {
        logger.info("Quran Sync: requested sign out confirmation from Account & Sync")
        let unsynced: MobileSyncUnsyncedItemCounts?
        do {
            unsynced = try await quranDataService.unsyncedItemsSequence().first { _ in true }
        } catch {
            logger.error("Quran Sync: failed to read the unsynced items before signing out: \(error)")
            unsynced = nil
        }
        // A cancelled read, such as a double tap's first, ends without counts; it mustn't replace a real read's.
        guard !Task.isCancelled else {
            return
        }
        unsyncedItems = unsynced
        isSignOutConfirmationPresented = true
    }

    /// Stays on this screen instead of signing out, showing the items that don't sync when there are any.
    func reviewUnsyncedItems() {
        logger.info("Quran Sync: reviewing unsynced items instead of signing out")
        scrollsToHeldItems = signOutWarning.showsHeldItems
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
    private let syncActivityBuilder: SyncActivityBuilder
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

    /// Fetches the profile the user may have just edited on Quran.com; the screen follows the user it publishes. A
    /// failure keeps the user shown.
    private func refreshProfile() {
        logger.info("Account & Sync: Quran.com profile closed, refreshing the profile")
        profileRefresh = Task { [quranDataService] in
            do {
                try await quranDataService.refreshProfile()
            } catch {
                logger.error("Quran Sync: failed to refresh the profile after Manage account closed: \(error)")
            }
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

// MARK: - SFSafariViewControllerDelegate

extension AccountSyncViewModel: @preconcurrency SFSafariViewControllerDelegate {
    /// The Manage account sheet closed. The user may have changed their name or photo there.
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        refreshProfile()
    }
}
#endif
