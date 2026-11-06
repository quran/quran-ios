#if QURAN_SYNC
import Localization
import MobileSync
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import QuranResources
import QuranTextKit
import UIKit
import XCTest
@testable import AnnotationsService
@testable import BookmarksFeature

@MainActor
final class AyahSetViewControllerTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        try await super.tearDown()
    }

    func test_editingPageWithAyahs_showsDeleteAllOnTheLeadingSide() throws {
        let viewModel = makeViewModel(collection: try collection(ayahs: [(1, 1)]))
        let viewController = AyahSetViewController(viewModel: viewModel)

        viewModel.editMode = .active

        let deleteAll = try XCTUnwrap(viewController.navigationItem.leftBarButtonItem)
        XCTAssertEqual(deleteAll.title, l("bookmarks.delete-all"))
        XCTAssertEqual(deleteAll.tintColor, .systemRed)
        XCTAssertTrue(viewController.navigationItem.hidesBackButton)
    }

    func test_editingEmptyPage_hasNoLeadingItem() throws {
        let viewModel = makeViewModel(collection: try collection(ayahs: []))
        let viewController = AyahSetViewController(viewModel: viewModel)

        viewModel.editMode = .active

        XCTAssertNil(viewController.navigationItem.leftBarButtonItem)
        XCTAssertFalse(viewController.navigationItem.hidesBackButton)
    }

    func test_notEditing_hasNoLeadingItem() throws {
        let viewModel = makeViewModel(collection: try collection(ayahs: [(1, 1)]))
        let viewController = AyahSetViewController(viewModel: viewModel)

        XCTAssertNil(viewController.navigationItem.leftBarButtonItem)
        XCTAssertFalse(viewController.navigationItem.hidesBackButton)
    }

    func test_removeAllAyahs_removesTheLeadingItem() async throws {
        let service = makeService()
        try await service.createCollection(named: "Personal")
        let personalID = try await storedCollection { $0.name == "Personal" }.id
        try await service.addAyahs([try ayah(1, 1)], toCollectionWithID: personalID)
        let personal = try await storedCollection { $0.id == personalID && $0.bookmarks.count == 1 }
        let viewModel = makeViewModel(collection: personal, service: service)
        let viewController = AyahSetViewController(viewModel: viewModel)
        viewModel.editMode = .active
        XCTAssertNotNil(viewController.navigationItem.leftBarButtonItem)
        XCTAssertTrue(viewController.navigationItem.hidesBackButton)

        await viewModel.removeAllAyahs()

        XCTAssertNil(viewController.navigationItem.leftBarButtonItem)
        XCTAssertFalse(viewController.navigationItem.hidesBackButton)
        XCTAssertNil(viewModel.error)
    }

    private func makeViewModel(
        collection: AyahBookmarkCollection,
        service: AyahBookmarkCollectionService? = nil
    ) -> AyahSetViewModel {
        AyahSetViewModel(
            dataSource: BookmarkCollectionAyahSetDataSource(collection: collection, service: service ?? makeService()),
            quranTextDataService: QuranTextDataService(
                databasesURL: URL(fileURLWithPath: "/tmp/unavailable-translations-database"),
                quranFileURL: QuranResources.quranUthmaniV2Database
            ),
            navigateToAyah: { _ in },
            dataSourceDeleted: {}
        )
    }

    private func makeService() -> AyahBookmarkCollectionService {
        AyahBookmarkCollectionService(quranDataService: database.quranDataService)
    }

    private func collection(ayahs: [(sura: Int, ayah: Int)]) throws -> AyahBookmarkCollection {
        AyahBookmarkCollection(
            id: "personal",
            name: "Personal",
            isDefault: false,
            isReadOnly: false,
            bookmarks: try ayahs.map { verse in
                AyahCollectionBookmark(
                    id: "\(verse.sura):\(verse.ayah)",
                    collectionID: "personal",
                    ayah: try ayah(verse.sura, verse.ayah)
                )
            }
        )
    }

    private func ayah(_ sura: Int, _ ayah: Int) throws -> AyahNumber {
        try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: sura, ayah: ayah))
    }

    private func storedCollection(
        where matches: (AyahBookmarkCollection) -> Bool
    ) async throws -> AyahBookmarkCollection {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        while let stored = try await iterator.next() {
            let collections = AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405)
            if let collection = collections.first(where: matches) {
                return collection
            }
        }
        throw AyahSetViewControllerTestError.expectedDatabaseStateNotObserved
    }
}

private enum AyahSetViewControllerTestError: Error {
    case expectedDatabaseStateNotObserved
}
#endif
