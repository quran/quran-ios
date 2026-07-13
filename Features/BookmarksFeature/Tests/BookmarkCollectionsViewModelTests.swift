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
    private let oldPageBookmarksCollectionName = "Old Page Bookmarks"

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

    func test_sorted_groupsHighlightCollectionsBeforeUserCollections() {
        let collections = BookmarkCollectionsViewModel.sorted([
            collection(name: "Z Collection"),
            collection(name: "blue"),
            collection(name: "A Collection"),
            collection(name: "red"),
        ])

        XCTAssertEqual(collections.map(\.collection.name), [
            "blue",
            "red",
            "A Collection",
            "Z Collection",
        ])
    }

    func test_deletableCollections_includesOldPageBookmarksAndUserCollections() {
        let collections = BookmarkCollectionsViewModel.deletableCollections(from: [
            collection(name: "red"),
            collection(name: "Favorites"),
            collection(name: oldPageBookmarksCollectionName),
        ])

        XCTAssertEqual(collections.map(\.collection.name), [
            oldPageBookmarksCollectionName,
            "Favorites",
        ])
    }

    func test_collectionKind_classifiesOldColoredAndUserCollections() {
        XCTAssertEqual(
            collection(name: oldPageBookmarksCollectionName).kind,
            .oldPageBookmarks
        )
        XCTAssertEqual(collection(name: "red").kind, .colored(.red))
        XCTAssertEqual(collection(name: "Favorites").kind, .user)
    }

    func test_collectionsViewController_hidesEditButtonWithoutDeletableCollections() {
        let viewController = BookmarkCollectionsViewController(viewModel: makeSUT())

        XCTAssertNil(viewController.navigationItem.leftBarButtonItem)
    }

    func test_collectionsViewController_showsEditButtonForOldPageBookmarks() async throws {
        let service = makeService()
        try await service.createCollection(named: oldPageBookmarksCollectionName)
        let sut = makeSUT(collectionService: service)
        let viewController = BookmarkCollectionsViewController(viewModel: sut)

        let task = Task { await sut.start() }
        await waitUntil { viewController.navigationItem.leftBarButtonItem != nil }

        XCTAssertNotNil(viewController.navigationItem.leftBarButtonItem)
        task.cancel()
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

    func test_login_setsAuthenticated_whenLoginSucceeds() async {
        let client = AuthenticationClientFake()
        let navigationController = UINavigationController()
        let sut = makeSUT(authenticationClient: client, navigationController: navigationController)

        await sut.loginToQuranCom()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(client.events, [.login])
        XCTAssertNil(sut.error)
    }

    func test_login_setsError_whenLoginFails() async {
        let client = AuthenticationClientFake()
        client.loginResult = .failure(.clientIsNotAuthenticated(TestError.loginFailed))
        let navigationController = UINavigationController()
        let sut = makeSUT(authenticationClient: client, navigationController: navigationController)

        await sut.loginToQuranCom()

        XCTAssertFalse(sut.isAuthenticated)
        guard case .clientIsNotAuthenticated = sut.error as? AuthenticationClientError else {
            return XCTFail("Expected clientIsNotAuthenticated, got \(String(describing: sut.error))")
        }
    }

    func test_dismissSyncBanner_persistsDismissal() {
        let sut = makeSUT()

        sut.dismissSyncBanner()

        XCTAssertTrue(sut.isSyncBannerDismissed)
        XCTAssertTrue(BookmarkCollectionsPreferences.shared.isSyncBannerDismissed)
        XCTAssertFalse(sut.shouldShowSyncBanner)
    }

    func test_createPendingCollection_persistsThroughRealMobileSyncDatabase() async throws {
        let sut = makeSUT()
        sut.newCollectionName = " Favorites "

        await sut.createPendingCollection()

        let collections = try await storedCollections()
        XCTAssertEqual(collections.map(\.collection.name), ["Favorites"])
        XCTAssertNil(sut.error)
    }

    func test_deleteCollection_removesFromRealMobileSyncDatabase() async throws {
        let service = makeService()
        try await service.createCollection(named: "Favorites")
        let stored = try await storedCollections()
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405).first
        )
        let sut = makeSUT(collectionService: service)

        await sut.deleteCollection(collection)

        let collections = try await storedCollections()
        XCTAssertTrue(collections.isEmpty)
        XCTAssertNil(sut.error)
    }

    func test_start_readsOldPageBookmarkCountFromMobileSync() async throws {
        let service = makeService()
        try await service.createCollection(named: oldPageBookmarksCollectionName)
        let collection = try await storedOldPageBookmarksCollection()
        try await service.addAyahBookmarkToCollection(
            collectionLocalId: collection.collection.localId,
            ayah: AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        )
        let sut = makeSUT(collectionService: service)

        let task = Task { await sut.start() }
        await waitUntil { sut.oldPageBookmarksCollection?.bookmarks.count == 1 }

        XCTAssertEqual(sut.oldPageBookmarksCollection?.bookmarks.count, 1)
        task.cancel()
    }

    func test_start_updatesOldPageBookmarkCount_whenMobileSyncChanges() async throws {
        let service = makeService()
        try await service.createCollection(named: oldPageBookmarksCollectionName)
        let collection = try await storedOldPageBookmarksCollection()
        let sut = makeSUT(collectionService: service)
        let task = Task { await sut.start() }

        try await service.addAyahBookmarkToCollection(
            collectionLocalId: collection.collection.localId,
            ayah: AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        )
        await waitUntil { sut.oldPageBookmarksCollection?.bookmarks.count == 1 }

        XCTAssertEqual(sut.oldPageBookmarksCollection?.bookmarks.count, 1)
        task.cancel()
    }

    func test_showCollection_pushesCollectionViewController() async throws {
        let service = makeService()
        try await service.createCollection(named: "Favorites")
        let stored = try await storedCollections()
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405).first
        )
        let navigationController = UINavigationController()
        let sut = makeSUT(
            collectionService: service,
            navigationController: navigationController
        )

        sut.showCollection(collection)

        XCTAssertTrue(navigationController.topViewController is AyahBookmarkCollectionsViewController)
        XCTAssertEqual(navigationController.topViewController?.title, collection.collection.name)
    }

    private func makeSUT(
        authenticationClient: any AuthenticationClient = UnavailableAuthenticationClient(),
        collectionService: AyahBookmarkCollectionService? = nil,
        navigationController: UINavigationController? = nil
    ) -> BookmarkCollectionsViewModel {
        let collectionService = collectionService ?? makeService()
        let navigationController = navigationController ?? UINavigationController()
        let collectionsBuilder = AyahBookmarkCollectionsBuilder(
            ayahBookmarkCollectionService: collectionService,
            navigateToPage: { _ in }
        )
        return BookmarkCollectionsViewModel(
            authenticationClient: authenticationClient,
            ayahBookmarkCollectionService: collectionService,
            collectionsBuilder: collectionsBuilder,
            navigationController: navigationController
        )
    }

    private func makeService() -> AyahBookmarkCollectionService {
        AyahBookmarkCollectionService(quranDataService: database.quranDataService)
    }

    private func storedOldPageBookmarksCollection() async throws -> CollectionWithAyahBookmarks {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        while let collections = try await iterator.next() {
            if let collection = collections.first(where: {
                $0.collection.name == oldPageBookmarksCollectionName
            }) {
                return collection
            }
        }
        throw TestError.collectionNotFound
    }

    private func storedCollections() async throws -> [CollectionWithAyahBookmarks] {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        return try await iterator.next() ?? []
    }

    private func collection(name: String) -> AyahBookmarkCollection {
        AyahBookmarkCollection(
            collection: Collection_(
                name: name,
                lastUpdated: .distantPast,
                localId: name
            ),
            bookmarks: []
        )
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
