#if QURAN_SYNC
import AnnotationsService
import Combine
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
@testable import ReadingBookmarkMenuFeature

@MainActor
final class ReadingBookmarkMenuViewModelTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared
    private var service: MobileSyncReadingBookmarkService!

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        service = MobileSyncReadingBookmarkService(quranDataService: database.quranDataService)
    }

    override func tearDown() async throws {
        try await database.reset()
        service = nil
        try await super.tearDown()
    }

    func test_start_showsUnsetLifecycleForEverySlot() async {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        XCTAssertEqual(sut.items.map(\.slot), ReadingBookmarkSlot.allCases)
        XCTAssertTrue(sut.items.allSatisfy {
            $0.subtitle.accessibilityText == "Not placed yet"
                && $0.action == .setHere
                && !$0.isCurrent
                && $0.isEnabled
        })
    }

    func test_start_describesCurrentAndPlacedElsewhereSlots() async throws {
        let selectedAyah = ayah(2)
        try await service.addReadingBookmark(at: .ayah(selectedAyah), slot: .coral)
        try await service.addReadingBookmark(at: .ayah(ayah(3)), slot: .teal)
        let sut = makeSUT(target: .ayah(selectedAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        let current = sut.items.first { $0.slot == .coral }
        XCTAssertEqual(current?.subtitle.accessibilityText, "Saved here")
        XCTAssertEqual(current?.action, .remove)
        XCTAssertEqual(current?.isCurrent, true)

        let elsewhere = sut.items.first { $0.slot == .teal }
        XCTAssertEqual(elsewhere?.subtitle.accessibilityText, "at Al-Fātihah, Ayah 3")
        XCTAssertEqual(elsewhere?.action, .moveHere)
        XCTAssertEqual(elsewhere?.isCurrent, false)
    }

    func test_selectUnsetSlot_persistsBookmarkAtTarget() async throws {
        let selectedAyah = ayah(2)
        let sut = makeSUT(target: .ayah(selectedAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        let toast = await sut.select(.teal)
        let storedBookmark = try await storedBookmark(in: .teal)

        XCTAssertEqual(storedBookmark?.location, .ayah(selectedAyah))
        XCTAssertNil(toast?.action)
    }

    func test_selectSlotPlacedElsewhere_movesOnlyThatSlot() async throws {
        let destination = ayah(2)
        try await service.addReadingBookmark(at: .ayah(ayah(1)), slot: .coral)
        try await service.addReadingBookmark(at: .ayah(ayah(3)), slot: .indigo)
        let sut = makeSUT(target: .ayah(destination))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        let toast = await sut.select(.indigo)
        let movedBookmark = try await storedBookmark(in: .indigo)
        let unchangedBookmark = try await storedBookmark(in: .coral)

        XCTAssertEqual(movedBookmark?.location, .ayah(destination))
        XCTAssertEqual(unchangedBookmark?.location, .ayah(ayah(1)))
        XCTAssertNotNil(toast?.action)
    }

    func test_selectSlotAlreadyAtTarget_removesIt() async throws {
        let selectedAyah = ayah(2)
        try await service.addReadingBookmark(at: .ayah(selectedAyah), slot: .coral)
        let sut = makeSUT(target: .ayah(selectedAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        let toast = await sut.select(.coral)
        let storedBookmark = try await storedBookmark(in: .coral)

        XCTAssertNil(storedBookmark)
        XCTAssertNotNil(toast?.action)
    }

    func test_removedBookmarkUndo_restoresPreviousLocation() async throws {
        let selectedAyah = ayah(2)
        try await service.addReadingBookmark(at: .ayah(selectedAyah), slot: .coral)
        let sut = makeSUT(target: .ayah(selectedAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        let toast = await sut.select(.coral)
        let restored = bookmarkExpectation(
            description: "Restores removed reading bookmark",
            slot: .coral,
            location: .ayah(selectedAyah)
        )

        toast?.action?.handler()
        await fulfillment(of: [restored.expectation], timeout: 2)

        restored.task.cancel()
    }

    func test_movedBookmarkUndo_restoresPreviousLocation() async throws {
        let previousAyah = ayah(1)
        try await service.addReadingBookmark(at: .ayah(previousAyah), slot: .indigo)
        let sut = makeSUT(target: .ayah(ayah(2)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        let toast = await sut.select(.indigo)
        let restored = bookmarkExpectation(
            description: "Restores moved reading bookmark",
            slot: .indigo,
            location: .ayah(previousAyah)
        )

        toast?.action?.handler()
        await fulfillment(of: [restored.expectation], timeout: 2)

        restored.task.cancel()
    }

    func test_start_updatesItemsWhenServicePublishesNewBookmark() async throws {
        let selectedAyah = ayah(2)
        let sut = makeSUT(target: .ayah(selectedAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        let observed = expectation(description: "Shows externally created reading bookmark")
        var didFulfill = false
        let observation = sut.$items.sink { items in
            guard !didFulfill,
                  items.first(where: { $0.slot == .indigo })?.isCurrent == true
            else {
                return
            }
            didFulfill = true
            observed.fulfill()
        }

        try await service.addReadingBookmark(at: .ayah(selectedAyah), slot: .indigo)
        await fulfillment(of: [observed], timeout: 2)

        observation.cancel()
    }

    func test_pageTarget_usesFirstVisiblePage() async throws {
        let firstPage = Quran.hafsMadani1405.pages[40]
        let secondPage = Quran.hafsMadani1405.pages[41]
        let sut = makeSUT(target: .pages(firstPage, [secondPage, firstPage]))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        _ = await sut.select(.teal)
        let storedBookmark = try await storedBookmark(in: .teal)

        XCTAssertEqual(storedBookmark?.location, .page(firstPage))
    }

    func test_pageTarget_describesBookmarkOnCurrentPage() async throws {
        let page = Quran.hafsMadani1405.pages[40]
        try await service.addReadingBookmark(at: .page(page), slot: .coral)
        let sut = makeSUT(target: .pages(page, [page]))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        let current = sut.items.first { $0.slot == .coral }
        XCTAssertEqual(current?.subtitle.accessibilityText, "Saved here")
        XCTAssertEqual(current?.action, .remove)
    }

    private func makeSUT(target: ReadingBookmarkMenuViewModel.Target) -> ReadingBookmarkMenuViewModel {
        ReadingBookmarkMenuViewModel(service: service, target: target)
    }

    private func start(_ sut: ReadingBookmarkMenuViewModel) async -> Task<Void, Never> {
        let observed = expectation(description: "Loads reading bookmarks")
        var didFulfill = false
        let observation = sut.$items.sink { items in
            guard !didFulfill, !items.isEmpty, items.allSatisfy(\.isEnabled) else {
                return
            }
            didFulfill = true
            observed.fulfill()
        }
        let task = Task { await sut.start() }

        await fulfillment(of: [observed], timeout: 2)
        observation.cancel()
        return task
    }

    private func storedBookmark(in slot: ReadingBookmarkSlot) async throws -> ReadingPositionBookmark? {
        var iterator = service.readingBookmarksSequence(quran: .hafsMadani1405).makeAsyncIterator()
        return try await iterator.next()?.first { $0.slot == slot }
    }

    private func bookmarkExpectation(
        description: String,
        slot: ReadingBookmarkSlot,
        location: ReadingPositionBookmark.Location
    ) -> (expectation: XCTestExpectation, task: Task<Void, Never>) {
        let expectation = expectation(description: description)
        let service = service!
        let task = Task {
            do {
                for try await bookmarks in service.readingBookmarksSequence(quran: .hafsMadani1405) {
                    if bookmarks.first(where: { $0.slot == slot })?.location == location {
                        expectation.fulfill()
                        return
                    }
                }
            } catch {
                XCTFail("Reading bookmark observation failed: \(error)")
            }
        }
        return (expectation, task)
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: number)!
    }
}
#endif
