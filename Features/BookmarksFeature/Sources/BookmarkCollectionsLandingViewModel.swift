#if QURAN_SYNC
//
//  BookmarkCollectionsLandingViewModel.swift
//

import AuthenticationClient
import Combine
import Foundation
import VLogging

@MainActor
final class BookmarkCollectionsLandingViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        authenticationClient: any AuthenticationClient,
        collectionService: AyahBookmarkCollectionService,
        loginAction: @escaping () async throws -> Void,
        showCollectionsAction: @escaping () -> Void,
        showOldPageBookmarksAction: @escaping () -> Void
    ) {
        self.authenticationClient = authenticationClient
        self.collectionService = collectionService
        self.loginAction = loginAction
        self.showCollectionsAction = showCollectionsAction
        self.showOldPageBookmarksAction = showOldPageBookmarksAction
        isSyncBannerDismissed = preferences.isSyncBannerDismissed
    }

    // MARK: Internal

    @Published var error: Error?
    @Published var isAuthenticated = false
    @Published var isSyncBannerDismissed: Bool
    @Published var oldPageBookmarksCount = 0

    var shouldShowSyncBanner: Bool {
        !isAuthenticated && !isSyncBannerDismissed
    }

    func start() async {
        isAuthenticated = await authenticationClient.safelyRestoreState() == .authenticated

        do {
            for try await collections in collectionService.collectionsSequence() {
                oldPageBookmarksCount = collections
                    .first { $0.collection.name == AyahBookmarkCollectionName.oldPageBookmarks }?
                    .bookmarks.count ?? 0
            }
        } catch {
            self.error = error
        }
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

    func showCollections() {
        showCollectionsAction()
    }

    func showOldPageBookmarks() {
        showOldPageBookmarksAction()
    }

    // MARK: Private

    private let authenticationClient: any AuthenticationClient
    private let collectionService: AyahBookmarkCollectionService
    private let loginAction: () async throws -> Void
    private let showCollectionsAction: () -> Void
    private let showOldPageBookmarksAction: () -> Void
    private let preferences = BookmarkCollectionsLandingPreferences.shared
}
#endif
