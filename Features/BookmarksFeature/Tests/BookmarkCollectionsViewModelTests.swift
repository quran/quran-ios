#if QURAN_SYNC
import Analytics
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
import ReadingService
import UIKit
import XCTest
@testable import AnnotationsService
@testable import BookmarksFeature

@MainActor
final class BookmarkCollectionsViewModelTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared
    private let oldPageBookmarksCollectionName = "Old Page Bookmarks"

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        AuthenticationPreferences.shared.isCollectionsSyncBannerDismissed = false
    }

    override func tearDown() async throws {
        AuthenticationPreferences.shared.isCollectionsSyncBannerDismissed = false
        try await database.reset()
        try await super.tearDown()
    }

    func test_sorted_sortsCollectionsByName() {
        let collections = BookmarkCollectionsViewModel.sorted([
            collection(name: "Z Collection"),
            collection(name: "B Collection"),
            collection(name: "A Collection"),
        ])

        XCTAssertEqual(collections.map(\.collection.name), [
            "A Collection",
            "B Collection",
            "Z Collection",
        ])
    }

    func test_deletableCollections_includesOldPageBookmarksAndUserCollections() {
        let collections = BookmarkCollectionsViewModel.deletableCollections(from: [
            collection(name: "Favorites"),
            collection(name: oldPageBookmarksCollectionName),
        ])

        XCTAssertEqual(collections.map(\.collection.name), [
            oldPageBookmarksCollectionName,
            "Favorites",
        ])
    }

    func test_displayedCollections_sortsDefaultThenOldPageBookmarksThenCustomCollections() {
        let collections = BookmarkCollectionsViewModel.displayedCollections(from: [
            collection(name: "Z Collection"),
            collection(name: oldPageBookmarksCollectionName),
            collection(name: "A Collection"),
            collection(name: "Default", id: "__default__"),
        ])

        XCTAssertEqual(collections.map(\.collection.name), [
            "Default",
            oldPageBookmarksCollectionName,
            "A Collection",
            "Z Collection",
        ])
    }

    func test_alphabeticallySortedColors_sortsLocalizedNames() {
        let colors = HighlightColor.alphabeticallySortedColors

        XCTAssertEqual(Set(colors), Set(HighlightColor.allCases))
        XCTAssertEqual(
            colors.map(\.localizedName),
            HighlightColor.allCases.map(\.localizedName).sorted {
                $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            }
        )
    }

    func test_collectionKind_classifiesCollectionNamesCaseInsensitively() {
        XCTAssertEqual(
            collection(name: oldPageBookmarksCollectionName.uppercased()).kind,
            .oldPageBookmarks
        )
        XCTAssertEqual(collection(name: "Default", id: "__default__").kind, .defaultBookmarks)
        XCTAssertEqual(collection(name: "Favorites").kind, .user)
    }

    func test_collectionCapabilities_protectDefaultCollection() {
        let defaultBookmarks = collection(name: "Default", id: "__default__")
        let oldPageBookmarks = collection(name: oldPageBookmarksCollectionName)
        let user = collection(name: "Favorites")

        XCTAssertFalse(defaultBookmarks.kind.canRename)
        XCTAssertFalse(defaultBookmarks.kind.canDelete)
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

    func test_collectionDetailsController_usesNativeTitleAndSubtitle() {
        let collection = collection(name: "Red")
        let viewModel = makeCollectionDetailsViewModel(collection: collection)
        let viewController = AyahSetViewController(viewModel: viewModel)
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
        let viewController = AyahSetViewController(viewModel: viewModel)

        let buttons = viewController.navigationItem.rightBarButtonItems
        let systemEditTitle = UIBarButtonItem(barButtonSystemItem: .edit, target: nil, action: nil).title
        let titles = buttons?.last?.menu?.children.map(\.title)

        XCTAssertEqual(buttons?.first?.title, systemEditTitle)
        XCTAssertEqual(titles, [
            l("bookmarks.collections.rename"),
            l("button.delete"),
        ])
    }

    func test_collectionDetailsController_showsDoneButtonInEditMode() {
        let collection = collection(name: "Favorites")
        let viewModel = makeCollectionDetailsViewModel(collection: collection)
        let viewController = AyahSetViewController(viewModel: viewModel)

        viewModel.editMode = .active

        let systemDoneTitle = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil).title
        XCTAssertEqual(viewController.navigationItem.rightBarButtonItem?.title, systemDoneTitle)
    }

    func test_collectionsViewController_hidesEditButtonWithoutDeletableCollections() {
        let viewController = BookmarkCollectionsViewController(viewModel: makeSUT())

        XCTAssertNil(viewController.navigationItem.leftBarButtonItem)
        XCTAssertEqual(viewController.navigationItem.rightBarButtonItems?.count, 1)
        XCTAssertNil(viewController.navigationItem.rightBarButtonItem?.title)
    }

    func test_collectionsViewController_showsEditButtonForOldPageBookmarks() async throws {
        let service = makeService()
        try await service.createCollection(named: oldPageBookmarksCollectionName)
        let sut = makeSUT(collectionService: service)
        let viewController = BookmarkCollectionsViewController(viewModel: sut)
        var cancellable: AnyCancellable?
        let collections = AsyncStream<[AyahBookmarkCollection]> { continuation in
            cancellable = sut.$collections.sink { continuation.yield($0) }
        }
        var iterator = collections.makeAsyncIterator()

        let task = Task { await sut.start() }
        defer {
            task.cancel()
            cancellable?.cancel()
        }

        while let collections = await iterator.next() {
            if !BookmarkCollectionsViewModel.deletableCollections(from: collections).isEmpty {
                break
            }
        }

        let systemEditTitle = UIBarButtonItem(barButtonSystemItem: .edit, target: nil, action: nil).title
        XCTAssertNil(viewController.navigationItem.leftBarButtonItem)
        XCTAssertEqual(viewController.navigationItem.rightBarButtonItems?.count, 2)
        XCTAssertEqual(viewController.navigationItem.rightBarButtonItems?.first?.title, systemEditTitle)
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
        client.restoreStateResult = .failure(.notAuthenticated(underlying: NSError(domain: "test", code: 1)))
        client.authenticationStateValue = .authenticated
        let sut = makeSUT(authenticationClient: client)

        let task = Task { await sut.start() }
        await waitUntil { sut.isAuthenticated }

        XCTAssertEqual(Array(client.events.prefix(2)), [.restoreState, .readAuthenticationState])
        task.cancel()
    }

    func test_login_setsAuthenticated_whenLoginSucceeds() async {
        let client = AuthenticationClientFake()
        client.authenticationStateValue = .authenticated
        let analytics = AnalyticsRecorder()
        let navigationController = UINavigationController()
        let sut = makeSUT(
            analytics: analytics,
            authenticationClient: client,
            navigationController: navigationController
        )

        await sut.loginToQuranCom()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(client.events, [.login, .readAuthenticationState])
        XCTAssertEqual(analytics.events, [.init(name: "QuranSyncSignIn", value: "bookmarks")])
        XCTAssertNil(sut.error)
    }

    func test_login_setsError_whenLoginFails() async {
        let client = AuthenticationClientFake()
        client.loginResult = .failure(.authenticationFailed(underlying: TestError.loginFailed))
        let navigationController = UINavigationController()
        let sut = makeSUT(authenticationClient: client, navigationController: navigationController)

        await sut.loginToQuranCom()

        XCTAssertFalse(sut.isAuthenticated)
        guard case .authenticationFailed = sut.error as? AuthenticationClientError else {
            return XCTFail("Expected authenticationFailed, got \(String(describing: sut.error))")
        }
    }

    func test_login_ignoresCancellation() async {
        let client = AuthenticationClientFake()
        client.loginResult = .failure(.cancelled)
        let navigationController = UINavigationController()
        let sut = makeSUT(authenticationClient: client, navigationController: navigationController)

        await sut.loginToQuranCom()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertEqual(client.events, [.login])
        XCTAssertNil(sut.error)
    }

    func test_dismissSyncBanner_persistsDismissal() {
        let analytics = AnalyticsRecorder()
        let sut = makeSUT(analytics: analytics)

        sut.dismissSyncBanner()

        XCTAssertTrue(sut.isSyncBannerDismissed)
        XCTAssertTrue(AuthenticationPreferences.shared.isCollectionsSyncBannerDismissed)
        XCTAssertFalse(sut.shouldShowSyncBanner)
        XCTAssertEqual(
            analytics.events,
            [.init(name: "QuranSyncSignInBannerDismissed", value: "bookmarks")]
        )
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

    func test_requestDeleteCollection_deletesEmptyCollectionWithoutConfirmation() async throws {
        let service = makeService()
        try await service.createCollection(named: "Favorites")
        let stored = try await storedCollections()
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405)
                .first { !$0.collection.isDefault }
        )
        let sut = makeSUT(collectionService: service)

        await sut.requestDeleteCollection(collection)

        let collections = try await storedCollections {
            $0.count == 1 && $0[0].collection.isDefault
        }
        XCTAssertEqual(collections.map(\.collection.name), ["Default"])
        XCTAssertTrue(collections[0].collection.isDefault)
        XCTAssertNil(sut.collectionPendingDeletion)
        XCTAssertNil(sut.error)
    }

    func test_requestDeleteCollection_requiresConfirmationBeforeDeletingNonEmptyCollection() async throws {
        let service = makeService()
        try await service.createCollection(named: "Favorites")
        var stored = try await storedCollections {
            $0.contains { $0.collection.name == "Favorites" }
        }
        let storedCollection = try XCTUnwrap(
            stored.first { $0.collection.name == "Favorites" }
        )
        try await service.addAyahBookmarkToCollection(
            collectionId: storedCollection.collection.id,
            ayah: AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        )
        stored = try await storedCollections {
            $0.first { $0.collection.name == "Favorites" }?.bookmarks.count == 1
        }
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405)
                .first { $0.collection.name == "Favorites" }
        )
        let sut = makeSUT(collectionService: service)

        await sut.requestDeleteCollection(collection)

        XCTAssertEqual(sut.collectionPendingDeletion?.id, collection.id)
        let unchangedCollections = try await storedCollections()
        XCTAssertTrue(unchangedCollections.contains { $0.collection.id == collection.id })

        await sut.deleteCollection(collection)

        let collectionsAfterConfirmation = try await storedCollections {
            !$0.contains { $0.collection.id == collection.id }
        }
        XCTAssertFalse(collectionsAfterConfirmation.contains { $0.collection.id == collection.id })
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

    func test_start_observesReadingBookmarkFromMobileSync() async throws {
        let service = makeReadingBookmarkService()
        let page = ReadingPreferences.shared.reading.quran.pages[269]
        let sut = makeSUT(readingBookmarkService: service)
        let task = Task { await sut.start() }

        try await service.addReadingBookmark(at: .page(page))
        await waitUntil { sut.readingBookmark?.location == .page(page) }

        XCTAssertEqual(sut.readingBookmark?.sura, page.firstVerse.sura)
        task.cancel()
    }

    func test_navigateToPageReadingBookmark_navigatesToPage() {
        let page = Quran.hafsMadani1405.pages[269]
        let bookmark = ReadingPositionBookmark(
            id: "reading-bookmark",
            location: .page(page),
            modifiedOn: .distantPast
        )
        var navigatedPage: Page?
        let sut = makeSUT(navigateToPage: { navigatedPage = $0 })

        sut.navigateTo(bookmark)

        XCTAssertEqual(navigatedPage, page)
    }

    func test_navigateToAyahReadingBookmark_navigatesToBookmarkedAyah() {
        let ayah = Quran.hafsMadani1405.pages[269].firstVerse
        let bookmark = ReadingPositionBookmark(
            id: "reading-bookmark",
            location: .ayah(ayah),
            modifiedOn: .distantPast
        )
        var navigatedAyah: AyahNumber?
        let sut = makeSUT(navigateToAyah: { navigatedAyah = $0 })

        sut.navigateTo(bookmark)

        XCTAssertEqual(navigatedAyah, ayah)
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

        XCTAssertTrue(navigationController.topViewController is AyahSetViewController)
        XCTAssertEqual(navigationController.topViewController?.title, collection.collection.name)
    }

    func test_showHighlights_pushesAyahSetViewController() throws {
        let navigationController = UINavigationController()
        let sut = makeSUT(navigationController: navigationController)
        let ayah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 255))
        sut.highlights = [ayah: .purple]

        sut.showHighlights(.purple)

        XCTAssertTrue(navigationController.topViewController is AyahSetViewController)
        XCTAssertEqual(navigationController.topViewController?.title, HighlightColor.purple.localizedName)
    }

    private func makeSUT(
        analytics: AnalyticsLibrary = AnalyticsRecorder(),
        authenticationClient: any AuthenticationClient = UnavailableAuthenticationClient(),
        collectionService: AyahBookmarkCollectionService? = nil,
        readingBookmarkService: MobileSyncReadingBookmarkService? = nil,
        navigationController: UINavigationController? = nil,
        navigateToPage: @escaping (Page) -> Void = { _ in },
        navigateToAyah: @escaping (AyahNumber) -> Void = { _ in }
    ) -> BookmarkCollectionsViewModel {
        let collectionService = collectionService ?? makeService()
        let readingBookmarkService = readingBookmarkService ?? makeReadingBookmarkService()
        let navigationController = navigationController ?? UINavigationController()
        let ayahSetBuilder = AyahSetBuilder(
            ayahBookmarkCollectionService: collectionService,
            ayahHighlightService: makeHighlightService(),
            quranTextDataService: makeQuranTextDataService(),
            navigateToAyah: { _ in }
        )
        return BookmarkCollectionsViewModel(
            analytics: analytics,
            authenticationClient: authenticationClient,
            ayahBookmarkCollectionService: collectionService,
            ayahHighlightService: makeHighlightService(),
            readingBookmarkService: readingBookmarkService,
            ayahSetBuilder: ayahSetBuilder,
            navigationController: navigationController,
            navigateToPage: navigateToPage,
            navigateToAyah: navigateToAyah
        )
    }

    private func makeService() -> AyahBookmarkCollectionService {
        AyahBookmarkCollectionService(quranDataService: database.quranDataService)
    }

    private func makeHighlightService() -> MobileSyncAyahHighlightService {
        MobileSyncAyahHighlightService(quranDataService: database.quranDataService)
    }

    private func makeReadingBookmarkService() -> MobileSyncReadingBookmarkService {
        MobileSyncReadingBookmarkService(quranDataService: database.quranDataService)
    }

    private func makeCollectionDetailsViewModel(
        collection: AyahBookmarkCollection
    ) -> AyahSetViewModel {
        let service = makeService()
        return AyahSetViewModel(
            dataSource: BookmarkCollectionAyahSetDataSource(
                collection: collection,
                service: service
            ),
            quranTextDataService: makeQuranTextDataService(),
            navigateToAyah: { _ in },
            dataSourceDeleted: {}
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

private struct AnalyticsEvent: Equatable {
    let name: String
    let value: String
}

private final class AnalyticsRecorder: AnalyticsLibrary, @unchecked Sendable {
    private(set) var events: [AnalyticsEvent] = []

    func logEvent(_ name: String, value: String) {
        events.append(.init(name: name, value: value))
    }
}
#endif
