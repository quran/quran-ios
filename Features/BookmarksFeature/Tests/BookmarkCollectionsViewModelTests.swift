#if QURAN_SYNC
import AuthenticationClient
import AuthenticationClientFake
import Combine
import MobileSync
import MobileSyncTestSupport
import QuranKit
import UIKit
import XCTest
@testable import BookmarksFeature

@MainActor
final class BookmarkCollectionsViewModelTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        BookmarkCollectionsPreferences.shared.isSyncBannerDismissed = false
    }

    override func tearDown() async throws {
        BookmarkCollectionsPreferences.shared.isSyncBannerDismissed = false
        try await database.reset()
        try await super.tearDown()
    }

    func test_start_setsAuthenticatedState_whenRestoreSucceeds() async {
        let client = AuthenticationClientFake()
        client.restoreStateResult = .success(.authenticated)
        let sut = makeSUT(authenticationClient: client)

        let task = Task { await sut.start() }
        await waitUntil { sut.isAuthenticated }

        XCTAssertEqual(client.events.first, .restoreState)
        task.cancel()
    }

    func test_start_fallsBackToCurrentState_whenRestoreFails() async {
        let client = AuthenticationClientFake()
        client.restoreStateResult = .failure(.clientIsNotAuthenticated(NSError(domain: "test", code: 1)))
        client.authenticationStateValue = .authenticated
        let sut = makeSUT(authenticationClient: client)

        let task = Task { await sut.start() }
        await waitUntil { sut.isAuthenticated }

        XCTAssertEqual(Array(client.events.prefix(2)), [.restoreState, .readAuthenticationState])
        task.cancel()
    }

    func test_login_setsAuthenticated_whenActionSucceeds() async {
        let client = AuthenticationClientFake()
        let sut = makeSUT(
            authenticationClient: client,
            loginAction: { try await client.login(on: UIViewController()) }
        )

        await sut.loginToQuranCom()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(client.events, [.login])
        XCTAssertNil(sut.error)
    }

    func test_login_setsError_whenActionFails() async {
        let expectedError = TestError.loginFailed
        let sut = makeSUT(loginAction: { throw expectedError })

        await sut.loginToQuranCom()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertEqual(sut.error as? TestError, expectedError)
    }

    func test_dismissSyncBanner_persistsDismissal() {
        let sut = makeSUT()

        sut.dismissSyncBanner()

        XCTAssertTrue(sut.isSyncBannerDismissed)
        XCTAssertTrue(BookmarkCollectionsPreferences.shared.isSyncBannerDismissed)
        XCTAssertFalse(sut.shouldShowSyncBanner)
    }

    func test_start_readsOldPageBookmarkCountFromMobileSync() async throws {
        let service = makeService()
        try await service.createCollection(named: AyahBookmarkCollectionName.oldPageBookmarks)
        let collection = try await storedOldPageBookmarksCollection()
        try await service.addAyahBookmarkToCollection(
            collectionLocalId: collection.collection.localId,
            ayah: AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        )
        let sut = makeSUT(collectionService: service)

        let task = Task { await sut.start() }
        await waitUntil { sut.oldPageBookmarksCount == 1 }

        XCTAssertEqual(sut.oldPageBookmarksCount, 1)
        task.cancel()
    }

    func test_start_updatesOldPageBookmarkCount_whenMobileSyncChanges() async throws {
        let service = makeService()
        try await service.createCollection(named: AyahBookmarkCollectionName.oldPageBookmarks)
        let collection = try await storedOldPageBookmarksCollection()
        let sut = makeSUT(collectionService: service)
        let task = Task { await sut.start() }

        try await service.addAyahBookmarkToCollection(
            collectionLocalId: collection.collection.localId,
            ayah: AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        )
        await waitUntil { sut.oldPageBookmarksCount == 1 }

        XCTAssertEqual(sut.oldPageBookmarksCount, 1)
        task.cancel()
    }

    func test_showOldPageBookmarks_invokesInjectedAction() {
        var shownOldPageBookmarks = false
        let sut = makeSUT(
            showOldPageBookmarksAction: { shownOldPageBookmarks = true }
        )

        sut.showOldPageBookmarks()

        XCTAssertTrue(shownOldPageBookmarks)
    }

    private func makeSUT(
        authenticationClient: any AuthenticationClient = UnavailableAuthenticationClient(),
        collectionService: AyahBookmarkCollectionService? = nil,
        loginAction: @escaping () async throws -> Void = {},
        showOldPageBookmarksAction: @escaping () -> Void = {}
    ) -> BookmarkCollectionsViewModel {
        let collectionService = collectionService ?? makeService()
        let collectionsViewModel = AyahBookmarkCollectionsViewModel(
            ayahBookmarkCollectionService: collectionService,
            excludedCollectionNames: [AyahBookmarkCollectionName.oldPageBookmarks],
            navigateToPage: { _ in }
        )
        return BookmarkCollectionsViewModel(
            authenticationClient: authenticationClient,
            collectionsViewModel: collectionsViewModel,
            loginAction: loginAction,
            showOldPageBookmarksAction: showOldPageBookmarksAction
        )
    }

    private func makeService() -> AyahBookmarkCollectionService {
        AyahBookmarkCollectionService(quranDataService: database.quranDataService)
    }

    private func storedOldPageBookmarksCollection() async throws -> CollectionWithAyahBookmarks {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        while let collections = try await iterator.next() {
            if let collection = collections.first(where: {
                $0.collection.name == AyahBookmarkCollectionName.oldPageBookmarks
            }) {
                return collection
            }
        }
        throw TestError.collectionNotFound
    }

    private func waitUntil(
        timeoutIterations: Int = 1000,
        condition: @escaping @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0 ..< timeoutIterations {
            if condition() {
                return
            }
            await Task.yield()
        }
        XCTFail("Condition was not met in time", file: file, line: line)
    }
}

private enum TestError: Error, Equatable {
    case collectionNotFound
    case loginFailed
}
#endif
