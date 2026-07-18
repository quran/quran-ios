#if QURAN_SYNC
import AuthenticationClient
import AuthenticationClientFake
import Combine
import Localization
import MobileSync
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import QuranResources
import QuranTextKit
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

    func test_displayedCollections_includesDefaultAndExcludesHighlights() {
        let collections = BookmarkCollectionsViewModel.displayedCollections(from: [
            collection(name: "Default", id: "__default__"),
            collection(name: "red"),
            collection(name: "Favorites"),
            collection(name: oldPageBookmarksCollectionName),
        ])

        XCTAssertEqual(collections.map(\.collection.name), [
            "Default",
            "Favorites",
            oldPageBookmarksCollectionName,
        ])
    }

    func test_collectionKind_classifiesCollectionNamesCaseInsensitively() {
        XCTAssertEqual(
            collection(name: oldPageBookmarksCollectionName.uppercased()).kind,
            .oldPageBookmarks
        )
        for color in HighlightColor.allCases {
            XCTAssertEqual(
                collection(name: color.collectionName.uppercased()).kind,
                .colored(color)
            )
        }
        XCTAssertEqual(collection(name: "Default", id: "__default__").kind, .defaultBookmarks)
        XCTAssertEqual(collection(name: "Favorites").kind, .user)
    }

    func test_collectionCapabilities_protectSystemCollections() {
        let defaultBookmarks = collection(name: "Default", id: "__default__")
        let highlight = collection(name: "Red")
        let oldPageBookmarks = collection(name: oldPageBookmarksCollectionName)
        let user = collection(name: "Favorites")

        XCTAssertFalse(defaultBookmarks.kind.canRename)
        XCTAssertFalse(defaultBookmarks.kind.canDelete)
        XCTAssertFalse(highlight.kind.canRename)
        XCTAssertFalse(highlight.kind.canDelete)
        XCTAssertTrue(oldPageBookmarks.kind.canRename)
        XCTAssertTrue(oldPageBookmarks.kind.canDelete)
        XCTAssertTrue(user.kind.canRename)
        XCTAssertTrue(user.kind.canDelete)
    }

    func test_defaultCollectionPresentation_usesLocalizedFavoritesNameAndFilledStarIcon() {
        let collection = collection(name: "Default", id: "__default__")

        XCTAssertEqual(collection.displayName, l("bookmarks.collections.favorites"))
        XCTAssertEqual(collection.displayImage, .starFilled)
    }

    func test_collectionDetailsController_showsDirectEditButtonForHighlightCollection() {
        let collection = collection(name: "Red")
        let viewModel = makeCollectionDetailsViewModel(collection: collection)
        let viewController = AyahBookmarkCollectionsViewController(viewModel: viewModel)

        let button = viewController.navigationItem.rightBarButtonItem

        XCTAssertEqual(button?.title, l("bookmarks.collections.edit.action"))
        XCTAssertNotNil(button?.primaryAction)
        XCTAssertNil(button?.menu)
    }

    func test_collectionDetailsController_usesNativeTitleAndSubtitle() {
        let collection = collection(name: "Red")
        let viewModel = makeCollectionDetailsViewModel(collection: collection)
        let viewController = AyahBookmarkCollectionsViewController(viewModel: viewModel)
        let title = collection.displayName
        let subtitle = lFormat("bookmarks.collections.ayahs.count", 0)

        if #available(iOS 26.0, *) {
            XCTAssertEqual(viewController.navigationItem.largeTitleDisplayMode, .always)
            XCTAssertEqual(viewController.title, title)
            XCTAssertEqual(viewController.navigationItem.subtitle, subtitle)
            XCTAssertEqual(viewController.navigationItem.largeTitle, title)
            XCTAssertEqual(viewController.navigationItem.largeSubtitle, subtitle)
        } else {
            XCTAssertEqual(viewController.title, "\(title) (\(subtitle))")
        }
    }

    func test_bookmarkCountLocalization_usesLocalePluralRules() {
        XCTAssertEqual(lFormat("bookmarks.collections.ayahs.count", language: .english, 0), "0 bookmarks")
        XCTAssertEqual(lFormat("bookmarks.collections.ayahs.count", language: .english, 1), "1 bookmark")
        XCTAssertEqual(lFormat("bookmarks.collections.ayahs.count", language: .english, 2), "2 bookmarks")

        let arabicFormat = l("bookmarks.collections.ayahs.count", language: .arabic)
        let arabicCount: (Int) -> String = {
            String(format: arabicFormat, locale: Locale(identifier: "ar"), arguments: [$0])
        }
        XCTAssertEqual(arabicCount(0), "لا توجد إشارات مرجعية")
        XCTAssertEqual(arabicCount(1), "إشارة مرجعية واحدة")
        XCTAssertEqual(arabicCount(2), "إشارتان مرجعيتان")
        XCTAssertEqual(arabicCount(3), "3 إشارات مرجعية")
        XCTAssertEqual(arabicCount(11), "11 إشارة مرجعية")
        XCTAssertEqual(arabicCount(100), "100 إشارة مرجعية")
    }

    func test_collectionDetailsMenu_showsAllActionsForUserCollection() {
        let collection = collection(name: "Favorites")
        let viewModel = makeCollectionDetailsViewModel(collection: collection)
        let viewController = AyahBookmarkCollectionsViewController(viewModel: viewModel)

        let titles = viewController.navigationItem.rightBarButtonItem?.menu?.children.map(\.title)

        XCTAssertEqual(titles, [
            l("bookmarks.collections.edit.action"),
            l("bookmarks.collections.rename"),
            l("button.delete"),
        ])
    }

    func test_collectionDetailsController_showsDoneButtonInEditMode() {
        let collection = collection(name: "Favorites")
        let viewModel = makeCollectionDetailsViewModel(collection: collection)
        let viewController = AyahBookmarkCollectionsViewController(viewModel: viewModel)

        viewModel.editMode = .active

        XCTAssertEqual(viewController.navigationItem.rightBarButtonItem?.title, l("button.done"))
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

        let collections = try await storedCollections {
            $0.contains { $0.collection.name == "Favorites" }
        }
        XCTAssertEqual(collections.map(\.collection.name), ["Default", "Favorites"])
        XCTAssertNil(sut.error)
    }

    func test_deleteCollection_removesFromRealMobileSyncDatabase() async throws {
        let service = makeService()
        try await service.createCollection(named: "Favorites")
        let stored = try await storedCollections()
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405)
                .first { !$0.collection.isDefault }
        )
        let sut = makeSUT(collectionService: service)

        await sut.deleteCollection(collection)

        let collections = try await storedCollections {
            $0.count == 1 && $0[0].collection.isDefault
        }
        XCTAssertEqual(collections.map(\.collection.name), ["Default"])
        XCTAssertTrue(collections[0].collection.isDefault)
        XCTAssertNil(sut.error)
    }

    func test_start_readsOldPageBookmarkCountFromMobileSync() async throws {
        let service = makeService()
        try await service.createCollection(named: oldPageBookmarksCollectionName)
        let collection = try await storedOldPageBookmarksCollection()
        try await service.addAyahBookmarkToCollection(
            collectionId: collection.collection.id,
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
            collectionId: collection.collection.id,
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
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405)
                .first { !$0.collection.isDefault }
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
            quranTextDataService: makeQuranTextDataService(),
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

    private func makeCollectionDetailsViewModel(
        collection: AyahBookmarkCollection
    ) -> AyahBookmarkCollectionsViewModel {
        AyahBookmarkCollectionsViewModel(
            ayahBookmarkCollectionService: makeService(),
            collection: collection,
            quranTextDataService: makeQuranTextDataService(),
            navigateToPage: { _ in },
            collectionDeleted: {}
        )
    }

    private func makeQuranTextDataService() -> QuranTextDataService {
        QuranTextDataService(
            databasesURL: URL(fileURLWithPath: "/tmp/unavailable-translations-database"),
            quranFileURL: QuranResources.quranUthmaniV2Database
        )
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

    private func storedCollections(
        where predicate: ([CollectionWithAyahBookmarks]) -> Bool = { _ in true }
    ) async throws -> [CollectionWithAyahBookmarks] {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        while let collections = try await iterator.next() {
            if predicate(collections) {
                return collections
            }
        }
        throw TestError.collectionNotFound
    }

    private func collection(name: String, id: String? = nil) -> AyahBookmarkCollection {
        AyahBookmarkCollection(
            collection: Collection_(
                name: name,
                lastUpdated: .distantPast,
                id: id ?? name
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
