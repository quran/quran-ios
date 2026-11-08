#if QURAN_SYNC
import Analytics
import AnalyticsFake
import MobileSync
import MobileSyncTestSupport
import NoorUI
import QuranAnnotations
import QuranKit
import XCTest
@testable import AnnotationsService
@testable import BookmarksFeature

@MainActor
final class BookmarkAyahsViewModelTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared
    private typealias Fixture = (
        collectionService: AyahBookmarkCollectionService,
        highlightService: MobileSyncAyahHighlightService,
        collections: [AyahBookmarkCollection],
        highlights: [AyahNumber: HighlightColor]
    )

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        BookmarksPreferences.shared.isCollectionsIntroRetired = false
    }

    override func tearDown() async throws {
        BookmarksPreferences.shared.isCollectionsIntroRetired = false
        try await database.reset()
        try await super.tearDown()
    }

    func test_selectingHighlightImmediatelyPersistsAcrossSuras() async throws {
        let fixture = try await makeFixture()
        let analytics = AnalyticsLibrarySpy()
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: fixture.collections,
            highlights: fixture.highlights,
            analytics: analytics,
            ayahBookmarkCollectionService: fixture.collectionService,
            ayahHighlightService: fixture.highlightService
        )

        await sut.selectHighlight(.green)

        let stored = try await storedHighlights()
        XCTAssertEqual(stored[verses[0]], .green)
        XCTAssertEqual(stored[verses[1]], .green)
        XCTAssertEqual(sut.highlightSelection, .color(.green))
        XCTAssertEqual(analytics.events, [.init(name: "HighlightVersesNum", value: "2")])
    }

    func test_togglingMixedCollectionImmediatelyAddsAllSelectedAyahs() async throws {
        let fixture = try await makeFixture()
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: fixture.collections,
            highlights: fixture.highlights,
            analytics: AnalyticsLibrarySpy(),
            ayahBookmarkCollectionService: fixture.collectionService,
            ayahHighlightService: fixture.highlightService
        )
        let study = try XCTUnwrap(sut.displayedCollections.first { $0.name == "Study" })
        XCTAssertEqual(sut.collectionSelection(for: study), .mixed)

        await sut.toggleCollection(study)

        let stored = try await storedCollections()
        XCTAssertEqual(bookmarkedAyahs(in: stored, named: "Study"), ["1:7", "2:1"])
        XCTAssertEqual(sut.collectionSelection(for: study), .selected)
    }

    func test_removingHighlightImmediatelyRemovesSelectedAyahs() async throws {
        let fixture = try await makeFixture()
        let analytics = AnalyticsLibrarySpy()
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: fixture.collections,
            highlights: fixture.highlights,
            analytics: analytics,
            ayahBookmarkCollectionService: fixture.collectionService,
            ayahHighlightService: fixture.highlightService
        )
        await sut.selectHighlight(nil)

        let stored = try await storedHighlights()
        XCTAssertNil(stored[verses[0]])
        XCTAssertNil(stored[verses[1]])
        XCTAssertEqual(sut.highlightSelection, .none)
        XCTAssertEqual(analytics.events, [.init(name: "UnhighlightVersesNum", value: "2")])
    }

    func test_mixedHighlightSelectionCanBeRemoved() async throws {
        let fixture = try await makeFixture()
        try await fixture.highlightService.removeHighlight(for: [verses[1]])
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: fixture.collections,
            highlights: try await storedHighlights(),
            analytics: AnalyticsLibrarySpy(),
            ayahBookmarkCollectionService: fixture.collectionService,
            ayahHighlightService: fixture.highlightService
        )
        XCTAssertEqual(sut.highlightSelection, .mixed([.pink]))
        XCTAssertEqual(sut.partiallySelectedHighlightColors, [.pink])

        await sut.selectHighlight(nil)

        let stored = try await storedHighlights()
        XCTAssertNil(stored[verses[0]])
        XCTAssertEqual(sut.highlightSelection, .none)
    }

    func test_mixedHighlightSelectionExposesEveryPartiallySelectedColor() async throws {
        let fixture = try await makeFixture()
        try await fixture.highlightService.setHighlight(.green, for: [verses[1]])
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: fixture.collections,
            highlights: try await storedHighlights(),
            analytics: AnalyticsLibrarySpy(),
            ayahBookmarkCollectionService: fixture.collectionService,
            ayahHighlightService: fixture.highlightService
        )

        XCTAssertEqual(sut.highlightSelection, .mixed([.pink, .green]))
        XCTAssertEqual(sut.partiallySelectedHighlightColors, [.pink, .green])
    }

    func test_dismissingCollectionsIntro_hidesItForThisAndLaterSheets() async throws {
        let fixture = try await makeFixture()
        let sut = makeViewModel(fixture)
        XCTAssertTrue(sut.isCollectionsIntroVisible)

        sut.dismissCollectionsIntro()

        XCTAssertFalse(sut.isCollectionsIntroVisible)
        XCTAssertFalse(makeViewModel(fixture).isCollectionsIntroVisible)
    }

    func test_togglingCollection_retiresCollectionsIntroForLaterSheets() async throws {
        let fixture = try await makeFixture()
        let sut = makeViewModel(fixture)
        let study = try XCTUnwrap(sut.displayedCollections.first { $0.name == "Study" })

        await sut.toggleCollection(study)

        XCTAssertTrue(sut.isCollectionsIntroVisible)
        XCTAssertFalse(makeViewModel(fixture).isCollectionsIntroVisible)
    }

    func test_changingHighlight_retiresCollectionsIntroForLaterSheets() async throws {
        let fixture = try await makeFixture()
        let sut = makeViewModel(fixture)

        await sut.selectHighlight(.green)

        XCTAssertTrue(sut.isCollectionsIntroVisible)
        XCTAssertFalse(makeViewModel(fixture).isCollectionsIntroVisible)
    }

    func test_creatingCollection_retiresCollectionsIntroForLaterSheets() async throws {
        let fixture = try await makeFixture()
        let sut = makeViewModel(fixture)
        sut.presentAddCollection()
        sut.newCollectionName = "Duas"

        await sut.createPendingCollection()

        XCTAssertTrue(sut.isCollectionsIntroVisible)
        XCTAssertFalse(makeViewModel(fixture).isCollectionsIntroVisible)
    }

    func test_titleShowsSingleAyah() {
        let title = BookmarkAyahsViewController.title(for: [verses[0]])

        XCTAssertEqual(title?.accessibilityText, verses[0].localizedName)
    }

    func test_titleShowsAyahRange() {
        let title = BookmarkAyahsViewController.title(for: verses)

        XCTAssertEqual(title?.accessibilityText, "Al-Fātihah, Ayah 7 to Al-Baqarah, Ayah 1")
    }

    private var verses: [AyahNumber] {
        [
            AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 7)!,
            AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 1)!,
        ]
    }

    func test_createPendingCollection_keepsTooLongNameAndShowsLimit() async throws {
        let fixture = try await makeFixture()
        let sut = makeViewModel(fixture)
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
        XCTAssertEqual(collections.count, 2)
        XCTAssertTrue(makeViewModel(fixture).isCollectionsIntroVisible)
    }

    func test_createPendingCollection_hidesAlertAfterRejectedNameIsFixed() async throws {
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: [],
            analytics: AnalyticsLibrarySpy(),
            ayahBookmarkCollectionService: makeCollectionService(),
            ayahHighlightService: makeHighlightService()
        )
        sut.presentAddCollection()
        sut.nameAlert = .hidden
        sut.newCollectionName = String(repeating: "a", count: 256)
        await sut.createPendingCollection()
        XCTAssertEqual(
            sut.nameAlert,
            .rejected(.textLength(TextLengthLimitError(field: .collectionName, bound: .tooLong, limit: 255)))
        )
        sut.newCollectionName = "Personal"

        await sut.createPendingCollection()

        XCTAssertEqual(sut.nameAlert, .hidden)
        XCTAssertEqual(sut.newCollectionName, "")
        XCTAssertNil(sut.error)
        let collections = try await mappedCollections()
        XCTAssertTrue(collections.contains { $0.name == "Personal" })
    }

    func test_createPendingCollection_keepsDuplicateNameAndShowsWhichCollectionHasIt() async throws {
        let collectionService = makeCollectionService()
        try await collectionService.createCollection(named: "Study")
        let sut = BookmarkAyahsViewModel(
            verses: verses,
            collections: [],
            analytics: AnalyticsLibrarySpy(),
            ayahBookmarkCollectionService: collectionService,
            ayahHighlightService: makeHighlightService()
        )
        sut.presentAddCollection()
        sut.nameAlert = .hidden
        sut.newCollectionName = "STUDY"

        await sut.createPendingCollection()

        XCTAssertEqual(sut.nameAlert, .rejected(.duplicate(DuplicateCollectionNameError(name: "Study"))))
        XCTAssertEqual(sut.newCollectionName, "STUDY")
        XCTAssertNil(sut.error)
        let collections = try await storedCollections()
        XCTAssertEqual(collections.count, 2)
    }

    private func makeFixture() async throws -> Fixture {
        let collectionService = makeCollectionService()
        let highlightService = makeHighlightService()
        try await collectionService.createCollection(named: "Study")

        var collections = try await mappedCollections()
        let study = try XCTUnwrap(collections.first { $0.name == "Study" })
        for verse in verses {
            try await highlightService.setHighlight(.pink, for: [verse])
        }
        try await collectionService.addAyahBookmarkToCollection(collectionId: study.id, ayah: verses[0])
        collections = try await mappedCollections()
        return (collectionService, highlightService, collections, try await storedHighlights(using: highlightService))
    }

    private func makeViewModel(_ fixture: Fixture) -> BookmarkAyahsViewModel {
        BookmarkAyahsViewModel(
            verses: verses,
            collections: fixture.collections,
            highlights: fixture.highlights,
            analytics: AnalyticsLibrarySpy(),
            ayahBookmarkCollectionService: fixture.collectionService,
            ayahHighlightService: fixture.highlightService
        )
    }

    private func mappedCollections() async throws -> [AyahBookmarkCollection] {
        AyahBookmarkCollectionService.collections(
            from: try await storedCollections(),
            quran: .hafsMadani1405
        )
    }

    private func storedCollections() async throws -> [MobileSyncCollectionWithBookmarks] {
        let iterator = database.quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        return try await iterator.next() ?? []
    }

    private func storedHighlights(
        using service: MobileSyncAyahHighlightService? = nil
    ) async throws -> [AyahNumber: HighlightColor] {
        let service = service ?? makeHighlightService()
        var iterator = service.highlightsSequence(quran: .hafsMadani1405).makeAsyncIterator()
        return try await iterator.next() ?? [:]
    }

    private func makeCollectionService() -> AyahBookmarkCollectionService {
        AyahBookmarkCollectionService(quranDataService: database.quranDataService)
    }

    private func makeHighlightService() -> MobileSyncAyahHighlightService {
        MobileSyncAyahHighlightService(quranDataService: database.quranDataService)
    }

    private func bookmarkedAyahs(
        in collections: [MobileSyncCollectionWithBookmarks],
        named name: String
    ) -> Set<String> {
        let collection = collections.first {
            $0.collection.name.caseInsensitiveCompare(name) == .orderedSame
        }
        return Set(collection?.bookmarks.map { "\($0.sura):\($0.ayah)" } ?? [])
    }
}

#endif
