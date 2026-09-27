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

    func test_start_showsUnplacedBookmarkForEverySlot() async {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        XCTAssertEqual(sut.items.map(\.slot), ReadingBookmarkSlot.allCases)
        XCTAssertTrue(sut.items.allSatisfy { $0.placement == .unplaced && $0.name == nil })
        XCTAssertFalse(sut.isMutating)
    }

    func test_start_exposesStoredPlacementsAndTarget() async throws {
        let selectedAyah = ayah(2)
        try await service.addReadingBookmark(at: .ayah(selectedAyah), slot: .green)
        try await service.addReadingBookmark(at: .ayah(ayah(3)), slot: .purple)
        let sut = makeSUT(target: .ayah(selectedAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        let current = sut.items.first { $0.slot == .green }
        XCTAssertEqual(current?.placement, .ayah(selectedAyah))
        XCTAssertEqual(sut.target.placement, .ayah(selectedAyah))

        let elsewhere = sut.items.first { $0.slot == .purple }
        XCTAssertEqual(elsewhere?.placement, .ayah(ayah(3)))
    }

    func test_selectUnsetSlot_persistsBookmarkAtTarget() async throws {
        let selectedAyah = ayah(2)
        let sut = makeSUT(target: .ayah(selectedAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        let toast = await sut.select(.purple)
        let storedBookmark = try await storedBookmark(in: .purple)

        XCTAssertEqual(storedBookmark?.placement, .ayah(selectedAyah))
        XCTAssertNil(toast?.action)
    }

    func test_selectSlotPlacedElsewhere_movesOnlyThatSlot() async throws {
        let destination = ayah(2)
        try await service.addReadingBookmark(at: .ayah(ayah(1)), slot: .green)
        try await service.addReadingBookmark(at: .ayah(ayah(3)), slot: .blue)
        let sut = makeSUT(target: .ayah(destination))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        let toast = await sut.select(.blue)
        let movedBookmark = try await storedBookmark(in: .blue)
        let unchangedBookmark = try await storedBookmark(in: .green)

        XCTAssertEqual(movedBookmark?.placement, .ayah(destination))
        XCTAssertEqual(unchangedBookmark?.placement, .ayah(ayah(1)))
        XCTAssertNotNil(toast?.action)
    }

    func test_selectSlotAlreadyAtTarget_removesIt() async throws {
        let selectedAyah = ayah(2)
        try await service.addReadingBookmark(at: .ayah(selectedAyah), slot: .green)
        let sut = makeSUT(target: .ayah(selectedAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        let toast = await sut.select(.green)
        let storedBookmark = try await storedBookmark(in: .green)

        XCTAssertNotNil(storedBookmark)
        XCTAssertEqual(storedBookmark?.placement, .unplaced)
        XCTAssertNotNil(toast?.action)
    }

    func test_removedBookmarkUndo_restoresPreviousLocation() async throws {
        let selectedAyah = ayah(2)
        try await service.addReadingBookmark(at: .ayah(selectedAyah), slot: .green)
        let sut = makeSUT(target: .ayah(selectedAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        let toast = await sut.select(.green)
        let restored = bookmarkExpectation(
            description: "Restores removed reading bookmark",
            slot: .green,
            placement: .ayah(selectedAyah)
        )

        toast?.action?.handler()
        await fulfillment(of: [restored.expectation], timeout: 2)

        restored.task.cancel()
    }

    func test_movedBookmarkUndo_restoresPreviousLocation() async throws {
        let previousAyah = ayah(1)
        try await service.addReadingBookmark(at: .ayah(previousAyah), slot: .blue)
        let sut = makeSUT(target: .ayah(ayah(2)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        let toast = await sut.select(.blue)
        let restored = bookmarkExpectation(
            description: "Restores moved reading bookmark",
            slot: .blue,
            placement: .ayah(previousAyah)
        )

        toast?.action?.handler()
        await fulfillment(of: [restored.expectation], timeout: 2)

        restored.task.cancel()
    }

    func test_removedBookmarkUndo_restoresPreviousLocationAfterSlotChanges() async throws {
        let previousAyah = ayah(2)
        try await service.addReadingBookmark(at: .ayah(previousAyah), slot: .green)
        let sut = makeSUT(target: .ayah(previousAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        let toast = await sut.select(.green)
        try await service.addReadingBookmark(at: .ayah(ayah(3)), slot: .green)
        let restored = bookmarkExpectation(
            description: "Restores removed bookmark over a later placement",
            slot: .green,
            placement: .ayah(previousAyah)
        )
        defer { restored.task.cancel() }

        try XCTUnwrap(toast?.action).handler()
        await fulfillment(of: [restored.expectation], timeout: 2)
    }

    func test_movedBookmarkUndo_restoresPreviousLocationAfterSlotChanges() async throws {
        let previousPage = Quran.hafsMadani1405.pages[40]
        try await service.addReadingBookmark(at: .page(previousPage), slot: .blue)
        let sut = makeSUT(target: .ayah(ayah(2)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        let toast = await sut.select(.blue)
        try await service.addReadingBookmark(at: .ayah(ayah(3)), slot: .blue)
        let restored = bookmarkExpectation(
            description: "Restores moved bookmark over a later placement",
            slot: .blue,
            placement: .page(previousPage)
        )
        defer { restored.task.cancel() }

        try XCTUnwrap(toast?.action).handler()
        await fulfillment(of: [restored.expectation], timeout: 2)
    }

    func test_start_updatesBookmarksWhenServicePublishesNewBookmark() async throws {
        let selectedAyah = ayah(2)
        let sut = makeSUT(target: .ayah(selectedAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        let observed = expectation(description: "Shows externally created reading bookmark")
        var didFulfill = false
        let observation = sut.objectWillChange.receive(on: RunLoop.main).sink {
            let bookmarks = sut.items
            guard !didFulfill,
                  bookmarks.first(where: { $0.slot == .blue })?.placement == .ayah(selectedAyah)
            else {
                return
            }
            didFulfill = true
            observed.fulfill()
        }

        try await service.addReadingBookmark(at: .ayah(selectedAyah), slot: .blue)
        await fulfillment(of: [observed], timeout: 2)

        observation.cancel()
    }

    func test_pageTarget_usesFirstVisiblePage() async throws {
        let firstPage = Quran.hafsMadani1405.pages[40]
        let secondPage = Quran.hafsMadani1405.pages[41]
        let sut = makeSUT(target: .pages(firstPage, [secondPage, firstPage]))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        _ = await sut.select(.purple)
        let storedBookmark = try await storedBookmark(in: .purple)

        XCTAssertEqual(storedBookmark?.placement, .page(firstPage))
    }

    func test_pageTarget_exposesBookmarkOnCurrentPage() async throws {
        let page = Quran.hafsMadani1405.pages[40]
        try await service.addReadingBookmark(at: .page(page), slot: .green)
        let sut = makeSUT(target: .pages(page, [page]))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        let current = sut.items.first { $0.slot == .green }
        XCTAssertEqual(current?.placement, .page(page))
        XCTAssertEqual(sut.target.placement, .page(page))
    }

    func test_clearedPin_isUnplacedAndDoesNotOfferMoveUndo() async throws {
        try await service.addReadingBookmark(at: .ayah(ayah(1)), slot: .green)
        try await service.clearReadingBookmark(in: .green)
        let sut = makeSUT(target: .ayah(ayah(2)))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        XCTAssertEqual(sut.items.first?.placement, .unplaced)

        let toast = await sut.select(.green)
        let stored = try await storedBookmark(in: .green)
        XCTAssertEqual(stored?.placement, .ayah(ayah(2)))
        XCTAssertNotNil(toast)
        XCTAssertNil(toast?.action)
    }

    func test_beginEditing_clearsDraftsWithoutCopyingSavedNames() async throws {
        try await service.renameReadingBookmark(in: .purple, name: "Review", quran: .hafsMadani1405)
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        sut.draftNames[.green] = "Discarded draft"
        sut.beginEditing()

        XCTAssertTrue(sut.draftNames.isEmpty)
        XCTAssertTrue(sut.editMode.isEditing)
        XCTAssertEqual(sut.items.first { $0.slot == .purple }?.name, "Review")
        XCTAssertNil(sut.items.first { $0.slot == .green }?.name)
    }

    func test_saveNames_singleSlotSavesTrimmedNameAndLeavesOtherDrafts() async throws {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        sut.beginEditing()
        sut.draftNames[.green] = "  Daily reading \n"
        sut.draftNames[.purple] = "Review"

        let saved = await sut.saveNames(in: [.green])
        let green = try await storedBookmark(in: .green)
        let purple = try await storedBookmark(in: .purple)

        XCTAssertTrue(saved)
        XCTAssertEqual(green?.name, "Daily reading")
        XCTAssertEqual(green?.placement, .unplaced)
        XCTAssertNil(purple)
        XCTAssertNil(sut.draftNames[.green])
        XCTAssertEqual(sut.draftNames[.purple], "Review")
        XCTAssertTrue(sut.editMode.isEditing)
    }

    func test_finishEditing_savesRemainingNamesAndExitsEditing() async throws {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        XCTAssertFalse(sut.editMode.isEditing)
        sut.beginEditing()
        sut.draftNames[.green] = "Daily reading"
        sut.draftNames[.purple] = "Review"

        await sut.finishEditing()
        let green = try await storedBookmark(in: .green)
        let purple = try await storedBookmark(in: .purple)

        XCTAssertFalse(sut.editMode.isEditing)
        XCTAssertEqual(green?.name, "Daily reading")
        XCTAssertEqual(purple?.name, "Review")
    }

    func test_finishEditing_whenSaveCannotRunKeepsEditingAndDrafts() async {
        let sut = makeSUT(target: .ayah(ayah(1)))
        sut.beginEditing()
        sut.draftNames[.green] = "Daily reading"

        await sut.finishEditing()

        XCTAssertTrue(sut.editMode.isEditing)
        XCTAssertEqual(sut.draftNames[.green], "Daily reading")
    }

    func test_editModeBinding_routesEditingAndSavingThroughViewModel() async throws {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        sut.editModeBinding.wrappedValue = .active
        XCTAssertTrue(sut.editMode.isEditing)
        sut.draftNames[.green] = "Daily reading"
        let finished = expectation(description: "Exits editing after saving")
        let observation = sut.$editMode
            .filter { !$0.isEditing }
            .prefix(1)
            .sink { _ in finished.fulfill() }
        defer { observation.cancel() }

        sut.editModeBinding.wrappedValue = .inactive
        await fulfillment(of: [finished], timeout: 2)
        let stored = try await storedBookmark(in: .green)

        XCTAssertFalse(sut.editMode.isEditing)
        XCTAssertEqual(stored?.name, "Daily reading")
    }

    func test_saveNames_allSlotsSavesRemainingChangesWithoutRewritingSubmittedName() async throws {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        sut.beginEditing()
        sut.draftNames[.green] = "Daily reading"
        sut.draftNames[.purple] = "Review"
        _ = await sut.saveNames(in: [.green])
        let submitted = try await storedBookmark(in: .green)

        let saved = await sut.saveNames(in: ReadingBookmarkSlot.allCases)
        let green = try await storedBookmark(in: .green)
        let purple = try await storedBookmark(in: .purple)
        let blue = try await storedBookmark(in: .blue)

        XCTAssertTrue(saved)
        XCTAssertEqual(green, submitted)
        XCTAssertEqual(purple?.name, "Review")
        XCTAssertNil(blue)
    }

    func test_saveNames_blankNameClearsCustomName() async throws {
        try await service.renameReadingBookmark(in: .green, name: "Daily reading", quran: .hafsMadani1405)
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        sut.beginEditing()
        sut.draftNames[.green] = " \n "

        let saved = await sut.saveNames(in: [.green])
        let stored = try await storedBookmark(in: .green)

        XCTAssertTrue(saved)
        XCTAssertNotNil(stored)
        XCTAssertNil(stored?.name)
        XCTAssertNil(sut.draftNames[.green])
    }

    func test_saveNames_publishesSavedNameToMenu() async {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        sut.beginEditing()
        sut.draftNames[.green] = "Daily reading"
        let observed = expectation(description: "Shows saved custom name")
        let observation = sut.objectWillChange
            .receive(on: RunLoop.main)
            .map { sut.items }
            .filter { $0.first(where: { $0.slot == .green })?.name == "Daily reading" }
            .prefix(1)
            .sink { _ in observed.fulfill() }
        defer { observation.cancel() }

        let saved = await sut.saveNames(in: [.green])
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertTrue(saved)
        sut.beginEditing()
        XCTAssertTrue(sut.draftNames.isEmpty)
        XCTAssertEqual(sut.items.first { $0.slot == .green }?.name, "Daily reading")
    }

    func test_saveNames_untouchedNameDoesNotWriteOrClearIt() async throws {
        try await service.renameReadingBookmark(in: .green, name: "Daily reading", quran: .hafsMadani1405)
        let original = try await storedBookmark(in: .green)
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        sut.beginEditing()

        let saved = await sut.saveNames(in: ReadingBookmarkSlot.allCases)
        let stored = try await storedBookmark(in: .green)

        XCTAssertTrue(saved)
        XCTAssertEqual(stored, original)
    }

    func test_saveNames_updatesBookmarkWithoutWaitingForObservation() async throws {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        startTask.cancel()
        await startTask.value
        sut.beginEditing()
        sut.draftNames[.green] = "Daily reading"

        let saved = await sut.saveNames(in: [.green])
        let submitted = try await storedBookmark(in: .green)
        await sut.finishEditing()
        let stored = try await storedBookmark(in: .green)

        XCTAssertTrue(saved)
        XCTAssertEqual(sut.items.first { $0.slot == .green }?.name, "Daily reading")
        XCTAssertEqual(sut.items.map(\.slot), ReadingBookmarkSlot.allCases)
        XCTAssertEqual(stored, submitted)
        sut.beginEditing()
        XCTAssertTrue(sut.draftNames.isEmpty)
    }

    private func makeSUT(target: ReadingBookmarkMenuViewModel.Target) -> ReadingBookmarkMenuViewModel {
        ReadingBookmarkMenuViewModel(service: service, target: target)
    }

    private func start(_ sut: ReadingBookmarkMenuViewModel) async -> Task<Void, Never> {
        let observed = expectation(description: "Loads reading bookmarks")
        var didFulfill = false
        let observation = sut.objectWillChange.receive(on: RunLoop.main).sink {
            guard !didFulfill, !sut.items.isEmpty, !sut.isMutating else {
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

    private func storedBookmark(in slot: ReadingBookmarkSlot) async throws -> ReadingBookmark? {
        var iterator = service.readingBookmarksSequence(quran: .hafsMadani1405).makeAsyncIterator()
        return try await iterator.next()?.first { $0.slot == slot }
    }

    private func bookmarkExpectation(
        description: String,
        slot: ReadingBookmarkSlot,
        placement: ReadingBookmark.Placement
    ) -> (expectation: XCTestExpectation, task: Task<Void, Never>) {
        let expectation = expectation(description: description)
        let service = service!
        let task = Task {
            do {
                for try await bookmarks in service.readingBookmarksSequence(quran: .hafsMadani1405) {
                    if bookmarks.first(where: { $0.slot == slot })?.placement == placement {
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
