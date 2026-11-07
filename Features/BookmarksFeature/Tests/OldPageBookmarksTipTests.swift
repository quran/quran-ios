#if QURAN_SYNC
import Localization
import QuranAnnotations
import QuranKit
import UIKit
import XCTest
@testable import AnnotationsService
@testable import BookmarksFeature
@testable import LegacyDataMigration

@MainActor
final class OldPageBookmarksTipTests: BookmarkCollectionsTestCase {
    override func setUp() async throws {
        try await super.setUp()
        BookmarksPreferences.reset()
        LegacyImportPreferences.reset()
    }

    override func tearDown() async throws {
        BookmarksPreferences.reset()
        LegacyImportPreferences.reset()
        try await super.tearDown()
    }

    func test_showsTip_forAnUpgraderWithOldPageBookmarks() async throws {
        LegacyImportPreferences.shared.hadPageBookmarks = true
        try await addOldPageBookmarks(withAyah: true)
        let sut = makeSUT()

        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil { sut.oldPageBookmarksCollection?.bookmarks.isEmpty == false }

        XCTAssertTrue(sut.showsOldPageBookmarksTip)
    }

    func test_showsTip_whenALaterImportRecordsPageBookmarks() async throws {
        try await addOldPageBookmarks(withAyah: true)
        let sut = makeSUT()
        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil { sut.oldPageBookmarksCollection?.bookmarks.isEmpty == false }
        XCTAssertFalse(sut.showsOldPageBookmarksTip)

        LegacyImportPreferences.shared.hadPageBookmarks = true

        await waitUntil { sut.showsOldPageBookmarksTip }
    }

    func test_hidesTip_withoutALegacyPageBookmarksImport() async throws {
        try await addOldPageBookmarks(withAyah: true)
        let sut = makeSUT()

        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil { sut.oldPageBookmarksCollection?.bookmarks.isEmpty == false }

        XCTAssertFalse(sut.showsOldPageBookmarksTip)
    }

    func test_hidesTip_whenOldPageBookmarksIsEmpty() async throws {
        LegacyImportPreferences.shared.hadPageBookmarks = true
        try await addOldPageBookmarks(withAyah: false)
        let sut = makeSUT()

        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil { sut.oldPageBookmarksCollection != nil }

        XCTAssertFalse(sut.showsOldPageBookmarksTip)
    }

    func test_hidesTip_inEditMode() async throws {
        LegacyImportPreferences.shared.hadPageBookmarks = true
        try await addOldPageBookmarks(withAyah: true)
        let sut = makeSUT()
        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil { sut.showsOldPageBookmarksTip }

        sut.editMode = .active

        XCTAssertFalse(sut.showsOldPageBookmarksTip)
    }

    func test_dismissTip_retiresItForANewViewModel() async throws {
        LegacyImportPreferences.shared.hadPageBookmarks = true
        try await addOldPageBookmarks(withAyah: true)
        makeSUT().dismissOldPageBookmarksTip()
        let sut = makeSUT()

        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil { sut.oldPageBookmarksCollection?.bookmarks.isEmpty == false }

        XCTAssertFalse(sut.showsOldPageBookmarksTip)
    }

    func test_openOldPageBookmarks_pushesTheCollectionAndRetiresTheTip() async throws {
        LegacyImportPreferences.shared.hadPageBookmarks = true
        try await addOldPageBookmarks(withAyah: true)
        let navigationController = UINavigationController()
        let sut = makeSUT(navigationController: navigationController)
        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil { sut.showsOldPageBookmarksTip }

        sut.openOldPageBookmarks()

        XCTAssertTrue(navigationController.topViewController is AyahSetViewController)
        XCTAssertEqual(navigationController.topViewController?.title, l("bookmarks.old-page-bookmarks"))
        XCTAssertFalse(sut.showsOldPageBookmarksTip)
    }

    // MARK: Private

    private func addOldPageBookmarks(withAyah: Bool) async throws {
        let service = makeService()
        try await service.createCollection(named: AyahBookmarkCollection.oldPageBookmarksName)
        guard withAyah else {
            return
        }
        let collection = try await storedCollection(named: AyahBookmarkCollection.oldPageBookmarksName)
        let ayah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1))
        try await service.addAyahBookmarkToCollection(collectionId: collection.collection.id, ayah: ayah)
    }
}
#endif
