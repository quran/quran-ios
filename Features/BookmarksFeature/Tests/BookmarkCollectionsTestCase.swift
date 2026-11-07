#if QURAN_SYNC
import AuthenticationClient
import AuthenticationClientFake
import MobileSync
import MobileSyncTestSupport
import QuranKit
import QuranResources
import QuranTextKit
import UIKit
import XCTest
@testable import AnnotationsService
@testable import BookmarksFeature

/// Builds the Bookmarks tab's view model over the real MobileSync test database.
@MainActor
class BookmarkCollectionsTestCase: XCTestCase {
    let database = MobileSyncTestDatabase.shared

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        try await super.tearDown()
    }

    func makeSUT(
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
            authenticationClient: authenticationClient,
            quranDataService: database.quranDataService,
            ayahBookmarkCollectionService: collectionService,
            ayahHighlightService: makeHighlightService(),
            readingBookmarkService: readingBookmarkService,
            ayahSetBuilder: ayahSetBuilder,
            navigationController: navigationController,
            navigateToPage: navigateToPage,
            navigateToAyah: navigateToAyah
        )
    }

    func makeService() -> AyahBookmarkCollectionService {
        AyahBookmarkCollectionService(quranDataService: database.quranDataService)
    }

    func makeHighlightService() -> MobileSyncAyahHighlightService {
        MobileSyncAyahHighlightService(quranDataService: database.quranDataService)
    }

    func makeReadingBookmarkService() -> MobileSyncReadingBookmarkService {
        MobileSyncReadingBookmarkService(quranDataService: database.quranDataService)
    }

    func makeQuranTextDataService() -> QuranTextDataService {
        QuranTextDataService(
            databasesURL: URL(fileURLWithPath: "/tmp/unavailable-translations-database"),
            quranFileURL: QuranResources.quranUthmaniV2Database
        )
    }

    func storedCollections(
        where predicate: ([MobileSyncCollectionWithBookmarks]) -> Bool = { _ in true }
    ) async throws -> [MobileSyncCollectionWithBookmarks] {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        while let collections = try await iterator.next() {
            if predicate(collections) {
                return collections
            }
        }
        throw CollectionNotFound()
    }

    func storedCollection(named name: String) async throws -> MobileSyncCollectionWithBookmarks {
        let collections = try await storedCollections { $0.contains { $0.collection.name == name } }
        return try XCTUnwrap(collections.first { $0.collection.name == name })
    }

    func waitUntil(
        timeout: TimeInterval = 10,
        condition: @escaping @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Condition was not met in time", file: file, line: line)
    }
}

private struct CollectionNotFound: Error {}
#endif
