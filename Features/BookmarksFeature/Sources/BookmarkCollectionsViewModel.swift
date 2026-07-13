#if QURAN_SYNC
//
//  BookmarkCollectionsViewModel.swift
//

import AuthenticationClient
import Combine
import Foundation
import VLogging

@MainActor
final class BookmarkCollectionsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        authenticationClient: any AuthenticationClient,
        collectionsViewModel: AyahBookmarkCollectionsViewModel,
        loginAction: @escaping () async throws -> Void,
        showOldPageBookmarksAction: @escaping () -> Void
    ) {
        self.authenticationClient = authenticationClient
        self.collectionsViewModel = collectionsViewModel
        self.loginAction = loginAction
        self.showOldPageBookmarksAction = showOldPageBookmarksAction
        isSyncBannerDismissed = preferences.isSyncBannerDismissed
    }

    // MARK: Internal

    @Published var error: Error?
    @Published var isAuthenticated = false
    @Published var isSyncBannerDismissed: Bool

    let collectionsViewModel: AyahBookmarkCollectionsViewModel

    var shouldShowSyncBanner: Bool {
        !isAuthenticated && !isSyncBannerDismissed
    }

    var oldPageBookmarksCount: Int {
        collectionsViewModel.allCollections
            .first { $0.collection.name == AyahBookmarkCollectionName.oldPageBookmarks }?
            .bookmarks.count ?? 0
    }

    func start() async {
        async let startCollections: Void = collectionsViewModel.start()
        isAuthenticated = await authenticationClient.safelyRestoreState() == .authenticated
        await startCollections
    }

    func loginToQuranCom() async {
        do {
            try await loginAction()
            isAuthenticated = true
        } catch {
            logger.error("Failed to login to Quran.com from bookmarks: \(error)")
            self.error = error
        }
    }

    func dismissSyncBanner() {
        isSyncBannerDismissed = true
        preferences.isSyncBannerDismissed = true
    }

    func showOldPageBookmarks() {
        showOldPageBookmarksAction()
    }

    // MARK: Private

    private let authenticationClient: any AuthenticationClient
    private let loginAction: () async throws -> Void
    private let showOldPageBookmarksAction: () -> Void
    private let preferences = BookmarkCollectionsPreferences.shared
}
#endif
