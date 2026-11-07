#if QURAN_SYNC
import AuthenticationClient
import AuthenticationClientFake
import Combine
import Localization
import MobileSync
import NoorUI
import QuranAnnotations
import QuranKit
import ReadingService
import UIKit
import XCTest
@testable import AnnotationsService
@testable import BookmarksFeature

@MainActor
final class BookmarkCollectionsViewModelTests: BookmarkCollectionsTestCase {
    private let oldPageBookmarksCollectionName = AyahBookmarkCollection.oldPageBookmarksName

    func test_sorted_sortsCollectionsByName() {
        let collections = BookmarkCollectionsViewModel.sorted([
            collection(name: "Z Collection"),
            collection(name: "B Collection"),
            collection(name: "A Collection"),
        ])

        XCTAssertEqual(collections.map(\.name), [
            "A Collection",
            "B Collection",
            "Z Collection",
        ])
    }

    func test_deletableCollections_includesOldPageBookmarksAndUserCollections() {
        let collections = BookmarkCollectionsViewModel.deletableCollections(from: [
            collection(name: "Personal"),
            collection(name: oldPageBookmarksCollectionName),
        ])

        XCTAssertEqual(collections.map(\.name), [
            oldPageBookmarksCollectionName,
            "Personal",
        ])
    }

    func test_displayedCollections_sortsDefaultThenOldPageBookmarksThenCustomCollections() {
        let collections = BookmarkCollectionsViewModel.displayedCollections(from: [
            collection(name: "Z Collection"),
            collection(name: oldPageBookmarksCollectionName),
            collection(name: "A Collection"),
            collection(name: "Default", id: "__default__", isDefault: true, isReadOnly: true),
        ])

        XCTAssertEqual(collections.map(\.name), [
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
        XCTAssertEqual(
            collection(name: "Default", id: "__default__", isDefault: true, isReadOnly: true).kind,
            .defaultBookmarks
        )
        XCTAssertEqual(collection(name: "Personal").kind, .user)
    }

    func test_defaultCollectionPresentation_usesLocalizedFavoritesNameAndFilledStarIcon() {
        let collection = collection(
            name: "Default",
            id: "__default__",
            isDefault: true,
            isReadOnly: true
        )

        XCTAssertEqual(collection.displayName, l("bookmarks.collections.favorites"))
        XCTAssertEqual(collection.displayImage, .starFilled)
    }

    func test_userCollectionPresentation_usesTheSameNeutralStarAsFavorites() {
        let favorites = collection(name: "Default", id: "__default__", isDefault: true, isReadOnly: true)
        let duas = collection(name: "Duas")

        XCTAssertEqual(duas.displayImage, .starFilled)
        XCTAssertEqual(duas.displayImageColor, favorites.displayImageColor)
        XCTAssertEqual(duas.displayImageColor, .secondaryLabel)
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
        let collection = collection(name: "Personal")
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
        let collection = collection(name: "Personal")
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

    func test_canRefresh_requiresSignIn_andStaysWhileEditing() {
        let sut = makeSUT()
        XCTAssertFalse(sut.canRefresh)

        sut.isAuthenticated = true
        XCTAssertTrue(sut.canRefresh)

        sut.editMode = .active
        XCTAssertTrue(sut.canRefresh)
    }

    func test_refresh_whileSignedOut_doesNotSync() async {
        let result = await makeSUT().refresh()

        XCTAssertNil(result)
    }

    func test_refresh_whenMobileSyncHasNoSession_returnsTheSyncsSignedOutResult() async {
        let sut = makeSUT()
        sut.isAuthenticated = true

        // MobileSync has no session here, so its sync ends at once.
        let result = await sut.refresh()

        XCTAssertEqual(result, .signedOut)
        XCTAssertNil(sut.error)
    }

    func test_signInAndSignOutElsewhere_showAndHidePullToRefresh() async throws {
        let client = AuthenticationClientFake()
        client.authenticationStateAfterLogin = .authenticated
        let sut = makeSUT(authenticationClient: client)

        try await client.login(on: UIViewController())
        await waitUntil { sut.canRefresh }

        try await client.logout()
        await waitUntil { !sut.canRefresh }
    }

    func test_createPendingCollection_persistsThroughRealMobileSyncDatabase() async throws {
        let sut = makeSUT()
        sut.newCollectionName = " Personal "

        await sut.createPendingCollection()

        let collections = try await storedCollections {
            $0.contains { $0.collection.name == "Personal" }
        }
        XCTAssertEqual(collections.count, 2)
        XCTAssertTrue(collections.contains { $0.collection.isDefault })
        XCTAssertTrue(collections.contains { $0.collection.name == "Personal" })
        XCTAssertNil(sut.error)
    }

    func test_createPendingCollection_hidesAlertAfterRejectedNameIsFixed() async throws {
        let sut = makeSUT()
        sut.presentAddCollection()
        sut.nameAlert = .hidden
        sut.newCollectionName = "system:notes"
        await sut.createPendingCollection()
        XCTAssertEqual(sut.nameAlert, .rejected(.reserved(ReservedCollectionNameError(name: "system:notes"))))
        sut.newCollectionName = "Personal"

        await sut.createPendingCollection()

        XCTAssertEqual(sut.nameAlert, .hidden)
        XCTAssertNil(sut.error)
        let collections = try await storedCollections {
            $0.contains { $0.collection.name == "Personal" }
        }
        XCTAssertEqual(collections.count, 2)
    }

    func test_createPendingCollection_keepsTooLongNameAndShowsLimit() async throws {
        let sut = makeSUT()
        let longName = String(repeating: "a", count: 256)
        sut.presentAddCollection()
        sut.nameAlert = .hidden
        sut.newCollectionName = longName

        await sut.createPendingCollection()

        XCTAssertEqual(
            sut.nameAlert,
            .rejected(.textLength(TextLengthLimitError(field: .collectionName, bound: .tooLong, limit: 255)))
        )
        XCTAssertEqual(sut.newCollectionName, longName)
        XCTAssertNil(sut.error)
        let collections = try await storedCollections()
        XCTAssertEqual(collections.count, 1)

        sut.nameAlert = .hidden
        sut.presentAddCollection()

        XCTAssertEqual(sut.nameAlert, .editing)
        XCTAssertEqual(sut.newCollectionName, "")
    }

    func test_createPendingCollection_keepsReservedNameAndExplainsIt() async throws {
        let sut = makeSUT()
        sut.presentAddCollection()
        sut.nameAlert = .hidden
        sut.newCollectionName = "system:notes"

        await sut.createPendingCollection()

        XCTAssertEqual(sut.nameAlert, .rejected(.reserved(ReservedCollectionNameError(name: "system:notes"))))
        XCTAssertEqual(
            sut.nameAlert.error?.localizedMessage,
            lFormat("bookmarks.collections.name.reserved", "system:notes")
        )
        XCTAssertEqual(sut.newCollectionName, "system:notes")
        XCTAssertNil(sut.error)
        let collections = try await storedCollections()
        XCTAssertEqual(collections.count, 1)
    }

    func test_createPendingCollection_keepsDuplicateNameAndShowsWhichCollectionHasIt() async throws {
        let service = makeService()
        try await service.createCollection(named: "Study")
        let sut = makeSUT(collectionService: service)
        sut.presentAddCollection()
        sut.nameAlert = .hidden
        sut.newCollectionName = " study "

        await sut.createPendingCollection()

        XCTAssertEqual(sut.nameAlert, .rejected(.duplicate(DuplicateCollectionNameError(name: "Study"))))
        XCTAssertEqual(sut.nameAlert.error?.localizedMessage, lFormat("bookmarks.collections.name.duplicate", "Study"))
        XCTAssertEqual(sut.newCollectionName, " study ")
        XCTAssertNil(sut.error)
        let collections = try await storedCollections()
        XCTAssertEqual(collections.count, 2)
    }

    func test_requestDeleteCollection_deletesEmptyCollectionWithoutConfirmation() async throws {
        let service = makeService()
        try await service.createCollection(named: "Personal")
        let stored = try await storedCollections()
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405)
                .first { !$0.isDefault }
        )
        let sut = makeSUT(collectionService: service)

        await sut.requestDeleteCollection(collection)

        let collections = try await storedCollections {
            $0.count == 1 && $0[0].collection.isDefault
        }
        XCTAssertTrue(collections[0].collection.isDefault)
        XCTAssertNil(sut.collectionPendingDeletion)
        XCTAssertNil(sut.error)
    }

    func test_deleteCollection_explainsWhenCollectionTurnedReadOnly() async throws {
        let stored = try await storedCollections { $0.contains { $0.collection.isDefault } }
        let favorites = try XCTUnwrap(stored.first { $0.collection.isDefault }?.collection)
        // A list the sync hadn't refreshed yet still offers to delete it.
        let staleCollection = collection(name: favorites.name, id: favorites.id)
        let sut = makeSUT(collectionService: makeService())

        await sut.deleteCollection(staleCollection)

        let error = try XCTUnwrap(sut.error as? ReadOnlyCollectionError)
        XCTAssertEqual(error, ReadOnlyCollectionError(collectionID: favorites.id))
        XCTAssertEqual(error.errorDescription, l("bookmarks.collections.read-only"))
        let collections = try await storedCollections()
        XCTAssertTrue(collections.contains { $0.collection.id == favorites.id })
    }

    func test_requestDeleteCollection_requiresConfirmationBeforeDeletingNonEmptyCollection() async throws {
        let service = makeService()
        try await service.createCollection(named: "Personal")
        var stored = try await storedCollections {
            $0.contains { $0.collection.name == "Personal" }
        }
        let storedCollection = try XCTUnwrap(
            stored.first { $0.collection.name == "Personal" }
        )
        try await service.addAyahBookmarkToCollection(
            collectionId: storedCollection.collection.id,
            ayah: AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        )
        stored = try await storedCollections {
            $0.first { $0.collection.name == "Personal" }?.bookmarks.count == 1
        }
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405)
                .first { $0.name == "Personal" }
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
        let collection = try await storedCollection(named: oldPageBookmarksCollectionName)
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
        let collection = try await storedCollection(named: oldPageBookmarksCollectionName)
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

        try await service.addReadingBookmark(at: .page(page), slot: .orange)
        await waitUntil { sut.readingBookmarks.first { $0.slot == .orange }?.placement == .page(page) }

        XCTAssertEqual(sut.readingBookmarks.first { $0.slot == .orange }?.suras, page.suras)
        task.cancel()
    }

    func test_start_hidesClearedReadingBookmarks() async throws {
        let service = makeReadingBookmarkService()
        let page = ReadingPreferences.shared.reading.quran.pages[269]
        let sut = makeSUT(readingBookmarkService: service)
        let task = Task { await sut.start() }
        defer { task.cancel() }
        try await service.addReadingBookmark(at: .page(page), slot: .orange)
        await waitUntil { sut.readingBookmarks.contains { $0.slot == .orange } }

        try await service.clearReadingBookmark(in: .orange)
        await waitUntil { sut.readingBookmarks.isEmpty }

        XCTAssertTrue(sut.readingBookmarks.isEmpty)
    }

    func test_start_remapsHighlightsAndCollections_whenReadingChanges() async throws {
        let readingPreferences = ReadingPreferences.shared
        let originalReading = readingPreferences.reading
        readingPreferences.reading = .hafs_1405
        defer { readingPreferences.reading = originalReading }
        let collectionService = makeService()
        try await collectionService.createCollection(named: "Personal")
        let stored = try await storedCollections { $0.contains { $0.collection.name == "Personal" } }
        let personal = try XCTUnwrap(stored.first { $0.collection.name == "Personal" })
        let madaniAyah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 255))
        let indoPakAyah = try XCTUnwrap(AyahNumber(quran: .hafsIndoPak, sura: 2, ayah: 255))
        try await collectionService.addAyahBookmarkToCollection(collectionId: personal.collection.id, ayah: madaniAyah)
        try await makeHighlightService().setHighlight(.purple, for: [madaniAyah])
        let sut = makeSUT(collectionService: collectionService)
        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil {
            sut.highlights == [madaniAyah: .purple]
                && sut.collections.first { $0.name == "Personal" }?.bookmarks.map(\.ayah) == [madaniAyah]
        }

        readingPreferences.reading = .indoPak

        await waitUntil {
            sut.highlights == [indoPakAyah: .purple]
                && sut.collections.first { $0.name == "Personal" }?.bookmarks.map(\.ayah) == [indoPakAyah]
        }
        XCTAssertEqual(sut.highlights.keys.map(\.quran), [.hafsIndoPak])
    }

    func test_deleteReadingBookmark_clearsBookmarkInMobileSync() async throws {
        let service = makeReadingBookmarkService()
        let page = ReadingPreferences.shared.reading.quran.pages[269]
        let bookmark = try await service.addReadingBookmark(at: .page(page), slot: .orange)
        let sut = makeSUT(readingBookmarkService: service)

        let toast = await sut.deleteReadingBookmark(bookmark)

        await waitUntilStoredReadingBookmarks { !$0.contains { $0.slot == .orange } }
        XCTAssertEqual(toast?.action?.title, lAndroid("undo"))
        XCTAssertNil(sut.error)
    }

    func test_deleteReadingBookmark_undoRestoresBookmarkInMobileSync() async throws {
        let service = makeReadingBookmarkService()
        let ayah = try XCTUnwrap(AyahNumber(quran: ReadingPreferences.shared.reading.quran, sura: 2, ayah: 255))
        let bookmark = try await service.addReadingBookmark(at: .ayah(ayah), slot: .teal)
        let sut = makeSUT(readingBookmarkService: service)
        let toast = await sut.deleteReadingBookmark(bookmark)

        try XCTUnwrap(toast?.action).handler()

        let stored = await waitUntilStoredReadingBookmarks { $0.contains { $0.slot == .teal } }
        XCTAssertEqual(stored.first { $0.slot == .teal }?.placement, .ayah(ayah))
        XCTAssertNil(sut.error)
    }

    func test_deleteReadingBookmark_undoKeepsBookmarkName() async throws {
        let service = makeReadingBookmarkService()
        let quran = ReadingPreferences.shared.reading.quran
        let page = quran.pages[269]
        try await service.addReadingBookmark(at: .page(page), slot: .red)
        let renamed = try await service.renameReadingBookmark(in: .red, name: "Night reading", quran: quran)
        let bookmark = try XCTUnwrap(PlacedReadingBookmark(renamed))
        let sut = makeSUT(readingBookmarkService: service)
        let toast = await sut.deleteReadingBookmark(bookmark)

        try XCTUnwrap(toast?.action).handler()

        let stored = await waitUntilStoredReadingBookmarks { $0.contains { $0.slot == .red } }
        let restored = try XCTUnwrap(stored.first { $0.slot == .red })
        XCTAssertEqual(restored.name, "Night reading")
        XCTAssertEqual(restored.placement, .page(page))
        XCTAssertNil(sut.error)
    }

    func test_presentRenameReadingBookmark_prefillsCustomName() throws {
        let ayah = try XCTUnwrap(AyahNumber(quran: ReadingPreferences.shared.reading.quran, sura: 2, ayah: 255))
        let bookmark = PlacedReadingBookmark(id: "teal", slot: .teal, placement: .ayah(ayah), modifiedOn: .distantPast, name: "Hifz")
        let sut = makeSUT()

        sut.presentRenameReadingBookmark(bookmark)

        XCTAssertEqual(sut.renamingReadingBookmark, .teal)
        XCTAssertEqual(sut.readingBookmarkName, "Hifz")
    }

    func test_presentRenameReadingBookmark_startsEmptyForUnnamedBookmark() {
        let page = ReadingPreferences.shared.reading.quran.pages[269]
        let bookmark = PlacedReadingBookmark(id: "red", slot: .red, placement: .page(page), modifiedOn: .distantPast)
        let sut = makeSUT()
        sut.readingBookmarkName = "Previous draft"

        sut.presentRenameReadingBookmark(bookmark)

        XCTAssertEqual(sut.renamingReadingBookmark, .red)
        XCTAssertEqual(sut.readingBookmarkName, "")
    }

    func test_renameReadingBookmark_storesTrimmedNameInMobileSync() async throws {
        let service = makeReadingBookmarkService()
        let page = ReadingPreferences.shared.reading.quran.pages[269]
        try await service.addReadingBookmark(at: .page(page), slot: .orange)
        let sut = makeSUT(readingBookmarkService: service)
        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil { sut.readingBookmarks.contains { $0.slot == .orange } }
        let bookmark = try XCTUnwrap(sut.readingBookmarks.first { $0.slot == .orange })
        sut.presentRenameReadingBookmark(bookmark)
        sut.readingBookmarkName = "  Khatmah \n"

        await sut.renameReadingBookmark(in: .orange)

        let stored = await waitUntilStoredReadingBookmarks { $0.first { $0.slot == .orange }?.name != nil }
        let renamed = try XCTUnwrap(stored.first { $0.slot == .orange })
        XCTAssertEqual(renamed.name, "Khatmah")
        XCTAssertEqual(renamed.placement, .page(page))
        XCTAssertNil(sut.error)
    }

    func test_renameReadingBookmark_emptyNameClearsCustomName() async throws {
        let service = makeReadingBookmarkService()
        let quran = ReadingPreferences.shared.reading.quran
        try await service.addReadingBookmark(at: .page(quran.pages[269]), slot: .red)
        try await service.renameReadingBookmark(in: .red, name: "Night reading", quran: quran)
        let sut = makeSUT(readingBookmarkService: service)
        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil { sut.readingBookmarks.first { $0.slot == .red }?.name == "Night reading" }
        let bookmark = try XCTUnwrap(sut.readingBookmarks.first { $0.slot == .red })
        sut.presentRenameReadingBookmark(bookmark)
        sut.readingBookmarkName = "   "

        await sut.renameReadingBookmark(in: .red)

        await waitUntilStoredReadingBookmarks { $0.contains { $0.slot == .red && $0.name == nil } }
        XCTAssertNil(sut.error)
    }

    func test_renameReadingBookmark_unchangedNameKeepsModifiedDate() async throws {
        let service = makeReadingBookmarkService()
        let quran = ReadingPreferences.shared.reading.quran
        try await service.addReadingBookmark(at: .page(quran.pages[269]), slot: .teal)
        let renamed = try await service.renameReadingBookmark(in: .teal, name: "Hifz", quran: quran)
        let sut = makeSUT(readingBookmarkService: service)
        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil { sut.readingBookmarks.first { $0.slot == .teal }?.name == "Hifz" }
        let bookmark = try XCTUnwrap(sut.readingBookmarks.first { $0.slot == .teal })
        sut.presentRenameReadingBookmark(bookmark)
        sut.readingBookmarkName = " Hifz  "

        await sut.renameReadingBookmark(in: .teal)

        let stored = await waitUntilStoredReadingBookmarks { $0.contains { $0.slot == .teal } }
        let current = try XCTUnwrap(stored.first { $0.slot == .teal })
        XCTAssertEqual(current.name, "Hifz")
        XCTAssertEqual(current.modifiedOn, renamed.modifiedOn)
        XCTAssertNil(sut.error)
    }

    func test_collectionsViewController_showsEditButtonForReadingBookmarksWithoutCustomCollections() async throws {
        let service = makeReadingBookmarkService()
        let page = ReadingPreferences.shared.reading.quran.pages[269]
        try await service.addReadingBookmark(at: .page(page), slot: .orange)
        let sut = makeSUT(readingBookmarkService: service)
        let viewController = BookmarkCollectionsViewController(viewModel: sut)
        let task = Task { await sut.start() }
        defer { task.cancel() }

        await waitUntil { viewController.navigationItem.rightBarButtonItems?.count == 2 }

        let systemEditTitle = UIBarButtonItem(barButtonSystemItem: .edit, target: nil, action: nil).title
        XCTAssertTrue(sut.deletableCollections.isEmpty)
        XCTAssertEqual(viewController.navigationItem.rightBarButtonItems?.first?.title, systemEditTitle)
    }

    func test_deleteReadingBookmark_exitsEditModeWhenNothingDeletableRemains() async throws {
        let service = makeReadingBookmarkService()
        let page = ReadingPreferences.shared.reading.quran.pages[269]
        let bookmark = try await service.addReadingBookmark(at: .page(page), slot: .orange)
        let sut = makeSUT(readingBookmarkService: service)
        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil { sut.readingBookmarks.contains { $0.slot == .orange } }
        sut.editMode = .active

        _ = await sut.deleteReadingBookmark(bookmark)
        await waitUntil { sut.readingBookmarks.isEmpty }

        XCTAssertEqual(sut.editMode, .inactive)
    }

    func test_navigateToPageReadingBookmark_navigatesToPage() {
        let page = Quran.hafsMadani1405.pages[269]
        let bookmark = QuranAnnotations.PlacedReadingBookmark(
            id: "reading-bookmark",
            slot: .teal,
            placement: .page(page),
            modifiedOn: .distantPast
        )
        var navigatedPage: Page?
        let sut = makeSUT(navigateToPage: { navigatedPage = $0 })

        sut.navigateTo(bookmark)

        XCTAssertEqual(navigatedPage, page)
    }

    func test_navigateToAyahReadingBookmark_navigatesToBookmarkedAyah() {
        let ayah = Quran.hafsMadani1405.pages[269].firstVerse
        let bookmark = QuranAnnotations.PlacedReadingBookmark(
            id: "reading-bookmark",
            slot: .teal,
            placement: .ayah(ayah),
            modifiedOn: .distantPast
        )
        var navigatedAyah: AyahNumber?
        let sut = makeSUT(navigateToAyah: { navigatedAyah = $0 })

        sut.navigateTo(bookmark)

        XCTAssertEqual(navigatedAyah, ayah)
    }

    func test_showCollection_pushesCollectionViewController() async throws {
        let service = makeService()
        try await service.createCollection(named: "Personal")
        let stored = try await storedCollections()
        let collection = try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405)
                .first { !$0.isDefault }
        )
        let navigationController = UINavigationController()
        let sut = makeSUT(
            collectionService: service,
            navigationController: navigationController
        )

        sut.showCollection(collection)

        XCTAssertTrue(navigationController.topViewController is AyahSetViewController)
        XCTAssertEqual(navigationController.topViewController?.title, collection.name)
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

    func test_renamePendingCollection_renamesCollectionInMobileSync() async throws {
        let service = makeService()
        try await service.createCollection(named: "Personal")
        let personal = try await storedAyahBookmarkCollection { $0.name == "Personal" }
        let sut = makeSUT(collectionService: service)
        sut.presentRenameCollection(personal)
        XCTAssertEqual(sut.renameAlert, .editing)
        XCTAssertEqual(sut.renamedCollectionName, "Personal")
        sut.renamedCollectionName = " Duas "

        await sut.renamePendingCollection()

        let renamed = try await storedAyahBookmarkCollection { $0.id == personal.id && $0.name == "Duas" }
        XCTAssertEqual(renamed.name, "Duas")
        XCTAssertEqual(sut.renameAlert, .hidden)
        XCTAssertEqual(sut.nameAlert, .hidden)
        XCTAssertEqual(sut.newCollectionName, "")
        XCTAssertNil(sut.error)
    }

    func test_renamePendingCollection_rejectsDuplicateName() async throws {
        let service = makeService()
        try await service.createCollection(named: "Study")
        try await service.createCollection(named: "Personal")
        let personal = try await storedAyahBookmarkCollection { $0.name == "Personal" }
        let sut = makeSUT(collectionService: service)
        sut.presentRenameCollection(personal)
        sut.renamedCollectionName = "study"

        await sut.renamePendingCollection()

        XCTAssertEqual(sut.renameAlert, .rejected(.duplicate(DuplicateCollectionNameError(name: "Study"))))
        XCTAssertEqual(sut.renamedCollectionName, "study")
        XCTAssertEqual(sut.nameAlert, .hidden)
        XCTAssertEqual(sut.newCollectionName, "")
        XCTAssertNil(sut.error)
        let unchanged = try await storedAyahBookmarkCollection { $0.id == personal.id }
        XCTAssertEqual(unchanged.name, "Personal")
    }

    func test_removeAllAyahs_emptiesReadOnlyFavoritesAndKeepsIt() async throws {
        let service = makeService()
        let emptyFavorites = try await storedAyahBookmarkCollection(where: \.isDefault)
        XCTAssertTrue(emptyFavorites.isReadOnly)
        let ayahs = try [(1, 1), (2, 255)].map { try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: $0, ayah: $1)) }
        try await service.addAyahs(ayahs, toCollectionWithID: emptyFavorites.id)
        let favorites = try await storedAyahBookmarkCollection { $0.isDefault && $0.bookmarks.count == 2 }
        let sut = makeSUT(collectionService: service)

        await sut.removeAllAyahs(from: favorites)

        let emptied = try await storedAyahBookmarkCollection { $0.id == favorites.id && $0.bookmarks.isEmpty }
        XCTAssertTrue(emptied.isDefault)
        XCTAssertTrue(emptied.bookmarks.isEmpty)
        XCTAssertNil(sut.error)
    }

    func test_renamePendingCollection_unchangedOldPageBookmarksNameDoesNotWrite() async throws {
        let service = makeService()
        try await service.createCollection(named: oldPageBookmarksCollectionName)
        let oldPageBookmarks = try await storedAyahBookmarkCollection { $0.kind == .oldPageBookmarks }
        let before = try await storedCollections()
        let lastUpdated = try XCTUnwrap(before.first { $0.collection.id == oldPageBookmarks.id }).collection.lastUpdated
        let sut = makeSUT(collectionService: service)
        sut.presentRenameCollection(oldPageBookmarks)
        XCTAssertEqual(sut.renamedCollectionName, l("bookmarks.old-page-bookmarks"))

        await sut.renamePendingCollection()

        XCTAssertEqual(sut.renameAlert, .hidden)
        XCTAssertNil(sut.error)
        let after = try await storedCollections()
        let stored = try XCTUnwrap(after.first { $0.collection.id == oldPageBookmarks.id })
        XCTAssertEqual(stored.collection.name, oldPageBookmarksCollectionName)
        XCTAssertEqual(stored.collection.lastUpdated, lastUpdated)
    }

    func test_userCollection_canBeRenamedAndHasNoRemoveAll() async throws {
        let service = makeService()
        try await service.createCollection(named: "Personal")
        let empty = try await storedAyahBookmarkCollection { $0.name == "Personal" }
        try await service.addAyahs([try ayah(1, 1)], toCollectionWithID: empty.id)
        let personal = try await storedAyahBookmarkCollection { $0.id == empty.id && $0.bookmarks.count == 1 }
        let sut = makeSUT(collectionService: service)

        XCTAssertTrue(personal.canRename)
        XCTAssertTrue(personal.canDelete)
        XCTAssertFalse(sut.canRemoveAllAyahs(from: personal))
    }

    func test_favoritesWithAyahs_canRemoveAll() async throws {
        let service = makeService()
        let empty = try await storedAyahBookmarkCollection(where: \.isDefault)
        try await service.addAyahs([try ayah(1, 1)], toCollectionWithID: empty.id)
        let favorites = try await storedAyahBookmarkCollection { $0.isDefault && $0.bookmarks.count == 1 }
        let sut = makeSUT(collectionService: service)

        XCTAssertFalse(favorites.canRename)
        XCTAssertFalse(favorites.canDelete)
        XCTAssertTrue(sut.canRemoveAllAyahs(from: favorites))
    }

    func test_emptyFavorites_hasNoMenuActions() async throws {
        let favorites = try await storedAyahBookmarkCollection(where: \.isDefault)
        let sut = makeSUT()

        XCTAssertTrue(favorites.bookmarks.isEmpty)
        XCTAssertFalse(favorites.canRename)
        XCTAssertFalse(favorites.canDelete)
        XCTAssertFalse(sut.canRemoveAllAyahs(from: favorites))
    }

    func test_editMode_turnsItemMenusOff() {
        let sut = makeSUT()
        XCTAssertTrue(sut.isItemMenuEnabled)

        sut.editMode = .active

        XCTAssertFalse(sut.isItemMenuEnabled)
    }

    func test_removeAllAyahs_removesAyahsAddedAfterTheMenuOpened() async throws {
        let service = makeService()
        let empty = try await storedAyahBookmarkCollection(where: \.isDefault)
        try await service.addAyahs([try ayah(1, 1)], toCollectionWithID: empty.id)
        let sut = makeSUT(collectionService: service)
        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil { sut.collections.first(where: \.isDefault)?.bookmarks.count == 1 }
        let staleFavorites = try XCTUnwrap(sut.collections.first(where: \.isDefault))
        // Added after the menu opened, and possibly before this screen sees it.
        try await service.addAyahs([try ayah(1, 2)], toCollectionWithID: empty.id)

        await sut.removeAllAyahs(from: staleFavorites)

        let emptied = try await storedAyahBookmarkCollection { $0.isDefault && $0.bookmarks.isEmpty }
        XCTAssertTrue(emptied.bookmarks.isEmpty)
        XCTAssertNil(sut.error)
    }

    func test_removeAllAyahs_holdsDeleteAllWhileRunning() async throws {
        let service = makeService()
        let empty = try await storedAyahBookmarkCollection(where: \.isDefault)
        try await service.addAyahs([try ayah(1, 1)], toCollectionWithID: empty.id)
        let favorites = try await storedAyahBookmarkCollection { $0.isDefault && $0.bookmarks.count == 1 }
        let sut = makeSUT(collectionService: service)
        var isRunning: [Bool] = []
        let observation = sut.$collectionIDsRemovingAllAyahs.sink { isRunning.append($0.contains(favorites.id)) }
        defer { observation.cancel() }

        await sut.removeAllAyahs(from: favorites)

        XCTAssertEqual(isRunning, [false, true, false])
        XCTAssertTrue(sut.canRemoveAllAyahs(from: favorites))
    }

    func test_removeAllHighlights_removesOnlySelectedColor() async throws {
        let highlightService = makeHighlightService()
        let pinkAyahs = try [1, 2].map { try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: $0)) }
        let greenAyah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 3))
        try await highlightService.setHighlight(.pink, for: pinkAyahs)
        try await highlightService.setHighlight(.green, for: [greenAyah])
        let sut = makeSUT()
        let task = Task { await sut.start() }
        defer { task.cancel() }
        await waitUntil { sut.highlights.count == 3 }

        await sut.removeAllHighlights(.pink)

        await waitUntil { sut.highlights == [greenAyah: .green] }
        var iterator = highlightService.highlightsSequence(quran: .hafsMadani1405).makeAsyncIterator()
        let stored = try await iterator.next()
        XCTAssertEqual(stored, [greenAyah: .green])
        XCTAssertNil(sut.error)
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

    private func ayah(_ sura: Int, _ ayah: Int) throws -> AyahNumber {
        try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: sura, ayah: ayah))
    }

    private func storedAyahBookmarkCollection(
        where matches: (AyahBookmarkCollection) -> Bool
    ) async throws -> AyahBookmarkCollection {
        let stored = try await storedCollections {
            AyahBookmarkCollectionService.collections(from: $0, quran: .hafsMadani1405).contains(where: matches)
        }
        return try XCTUnwrap(
            AyahBookmarkCollectionService.collections(from: stored, quran: .hafsMadani1405).first(where: matches)
        )
    }

    /// Observes the stored reading bookmarks until they match, failing the test after `waitUntil`'s timeout.
    @discardableResult
    private func waitUntilStoredReadingBookmarks(
        file: StaticString = #filePath,
        line: UInt = #line,
        where predicate: @escaping @MainActor ([PlacedReadingBookmark]) -> Bool
    ) async -> [PlacedReadingBookmark] {
        let latest = LatestReadingBookmarks()
        let sequence = makeReadingBookmarkService().placedReadingBookmarksSequence(quran: ReadingPreferences.shared.reading.quran)
        let observation = Task { @MainActor in
            for try await bookmarks in sequence {
                latest.value = bookmarks
            }
        }
        defer { observation.cancel() }

        await waitUntil(condition: { latest.value.map(predicate) ?? false }, file: file, line: line)
        return latest.value ?? []
    }

    private func collection(
        name: String,
        id: String? = nil,
        isDefault: Bool = false,
        isReadOnly: Bool = false
    ) -> AyahBookmarkCollection {
        AyahBookmarkCollection(id: id ?? name, name: name, isDefault: isDefault, isReadOnly: isReadOnly, bookmarks: [])
    }
}

@MainActor
private final class LatestReadingBookmarks {
    var value: [PlacedReadingBookmark]?
}

#endif
