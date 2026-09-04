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
        try await service.addReadingBookmark(at: .ayah(selectedAyah), slot: .coral)
        try await service.addReadingBookmark(at: .ayah(ayah(3)), slot: .teal)
        let sut = makeSUT(target: .ayah(selectedAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        let current = sut.items.first { $0.slot == .coral }
        XCTAssertEqual(current?.placement, .ayah(selectedAyah))
        XCTAssertEqual(sut.target.placement, .ayah(selectedAyah))

        let elsewhere = sut.items.first { $0.slot == .teal }
        XCTAssertEqual(elsewhere?.placement, .ayah(ayah(3)))
    }

    func test_selectUnsetSlot_persistsBookmarkAtTarget() async throws {
        let selectedAyah = ayah(2)
        let sut = makeSUT(target: .ayah(selectedAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        let toast = await sut.select(.teal)
        let storedBookmark = try await storedBookmark(in: .teal)

        XCTAssertEqual(storedBookmark?.placement, .ayah(selectedAyah))
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

        XCTAssertEqual(movedBookmark?.placement, .ayah(destination))
        XCTAssertEqual(unchangedBookmark?.placement, .ayah(ayah(1)))
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

        XCTAssertNotNil(storedBookmark)
        XCTAssertEqual(storedBookmark?.placement, .unplaced)
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
            placement: .ayah(selectedAyah)
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
            placement: .ayah(previousAyah)
        )

        toast?.action?.handler()
        await fulfillment(of: [restored.expectation], timeout: 2)

        restored.task.cancel()
    }

    func test_removedBookmarkUndo_restoresPreviousLocationAfterSlotChanges() async throws {
        let previousAyah = ayah(2)
        try await service.addReadingBookmark(at: .ayah(previousAyah), slot: .coral)
        let sut = makeSUT(target: .ayah(previousAyah))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        let toast = await sut.select(.coral)
        try await service.addReadingBookmark(at: .ayah(ayah(3)), slot: .coral)
        let restored = bookmarkExpectation(
            description: "Restores removed bookmark over a later placement",
            slot: .coral,
            placement: .ayah(previousAyah)
        )
        defer { restored.task.cancel() }

        try XCTUnwrap(toast?.action).handler()
        await fulfillment(of: [restored.expectation], timeout: 2)
    }

    func test_movedBookmarkUndo_restoresPreviousLocationAfterSlotChanges() async throws {
        let previousPage = Quran.hafsMadani1405.pages[40]
        try await service.addReadingBookmark(at: .page(previousPage), slot: .indigo)
        let sut = makeSUT(target: .ayah(ayah(2)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        let toast = await sut.select(.indigo)
        try await service.addReadingBookmark(at: .ayah(ayah(3)), slot: .indigo)
        let restored = bookmarkExpectation(
            description: "Restores moved bookmark over a later placement",
            slot: .indigo,
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
                  bookmarks.first(where: { $0.slot == .indigo })?.placement == .ayah(selectedAyah)
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

        XCTAssertEqual(storedBookmark?.placement, .page(firstPage))
    }

    func test_pageTarget_exposesBookmarkOnCurrentPage() async throws {
        let page = Quran.hafsMadani1405.pages[40]
        try await service.addReadingBookmark(at: .page(page), slot: .coral)
        let sut = makeSUT(target: .pages(page, [page]))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        let current = sut.items.first { $0.slot == .coral }
        XCTAssertEqual(current?.placement, .page(page))
        XCTAssertEqual(sut.target.placement, .page(page))
    }

    func test_clearedPin_isUnplacedAndDoesNotOfferMoveUndo() async throws {
        try await service.addReadingBookmark(at: .ayah(ayah(1)), slot: .coral)
        try await service.clearReadingBookmark(in: .coral)
        let sut = makeSUT(target: .ayah(ayah(2)))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        XCTAssertEqual(sut.items.first?.placement, .unplaced)

        let toast = await sut.select(.coral)
        let stored = try await storedBookmark(in: .coral)
        XCTAssertEqual(stored?.placement, .ayah(ayah(2)))
        XCTAssertNotNil(toast)
        XCTAssertNil(toast?.action)
    }

    func test_beginEditing_clearsDraftsWithoutCopyingSavedNames() async throws {
        try await service.renameReadingBookmark(in: .teal, name: "Review", quran: .hafsMadani1405)
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }

        sut.draftNames[.coral] = "Discarded draft"
        sut.beginEditing()

        XCTAssertTrue(sut.draftNames.isEmpty)
        XCTAssertTrue(sut.editMode.isEditing)
        XCTAssertEqual(sut.items.first { $0.slot == .teal }?.name, "Review")
        XCTAssertNil(sut.items.first { $0.slot == .coral }?.name)
    }

    func test_saveNames_singleSlotSavesTrimmedNameAndLeavesOtherDrafts() async throws {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        sut.beginEditing()
        sut.draftNames[.coral] = "  Daily reading \n"
        sut.draftNames[.teal] = "Review"

        let saved = await sut.saveNames(in: [.coral])
        let coral = try await storedBookmark(in: .coral)
        let teal = try await storedBookmark(in: .teal)

        XCTAssertTrue(saved)
        XCTAssertEqual(coral?.name, "Daily reading")
        XCTAssertEqual(coral?.placement, .unplaced)
        XCTAssertNil(teal)
        XCTAssertNil(sut.draftNames[.coral])
        XCTAssertEqual(sut.draftNames[.teal], "Review")
        XCTAssertTrue(sut.editMode.isEditing)
    }

    func test_finishEditing_savesRemainingNamesAndExitsEditing() async throws {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        XCTAssertFalse(sut.editMode.isEditing)
        sut.beginEditing()
        sut.draftNames[.coral] = "Daily reading"
        sut.draftNames[.teal] = "Review"

        await sut.finishEditing()
        let coral = try await storedBookmark(in: .coral)
        let teal = try await storedBookmark(in: .teal)

        XCTAssertFalse(sut.editMode.isEditing)
        XCTAssertEqual(coral?.name, "Daily reading")
        XCTAssertEqual(teal?.name, "Review")
    }

    func test_finishEditing_whenSaveCannotRunKeepsEditingAndDrafts() async {
        let sut = makeSUT(target: .ayah(ayah(1)))
        sut.beginEditing()
        sut.draftNames[.coral] = "Daily reading"

        await sut.finishEditing()

        XCTAssertTrue(sut.editMode.isEditing)
        XCTAssertEqual(sut.draftNames[.coral], "Daily reading")
    }

    func test_editModeBinding_routesEditingAndSavingThroughViewModel() async throws {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        sut.editModeBinding.wrappedValue = .active
        XCTAssertTrue(sut.editMode.isEditing)
        sut.draftNames[.coral] = "Daily reading"
        let finished = expectation(description: "Exits editing after saving")
        let observation = sut.$editMode
            .filter { !$0.isEditing }
            .prefix(1)
            .sink { _ in finished.fulfill() }
        defer { observation.cancel() }

        sut.editModeBinding.wrappedValue = .inactive
        await fulfillment(of: [finished], timeout: 2)
        let stored = try await storedBookmark(in: .coral)

        XCTAssertFalse(sut.editMode.isEditing)
        XCTAssertEqual(stored?.name, "Daily reading")
    }

    func test_saveNames_allSlotsSavesRemainingChangesWithoutRewritingSubmittedName() async throws {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        sut.beginEditing()
        sut.draftNames[.coral] = "Daily reading"
        sut.draftNames[.teal] = "Review"
        _ = await sut.saveNames(in: [.coral])
        let submitted = try await storedBookmark(in: .coral)

        let saved = await sut.saveNames(in: ReadingBookmarkSlot.allCases)
        let coral = try await storedBookmark(in: .coral)
        let teal = try await storedBookmark(in: .teal)
        let indigo = try await storedBookmark(in: .indigo)

        XCTAssertTrue(saved)
        XCTAssertEqual(coral, submitted)
        XCTAssertEqual(teal?.name, "Review")
        XCTAssertNil(indigo)
    }

    func test_saveNames_blankNameClearsCustomName() async throws {
        try await service.renameReadingBookmark(in: .coral, name: "Daily reading", quran: .hafsMadani1405)
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        sut.beginEditing()
        sut.draftNames[.coral] = " \n "

        let saved = await sut.saveNames(in: [.coral])
        let stored = try await storedBookmark(in: .coral)

        XCTAssertTrue(saved)
        XCTAssertNotNil(stored)
        XCTAssertNil(stored?.name)
        XCTAssertNil(sut.draftNames[.coral])
    }

    func test_saveNames_publishesSavedNameToMenu() async {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        sut.beginEditing()
        sut.draftNames[.coral] = "Daily reading"
        let observed = expectation(description: "Shows saved custom name")
        let observation = sut.objectWillChange
            .receive(on: RunLoop.main)
            .map { sut.items }
            .filter { $0.first(where: { $0.slot == .coral })?.name == "Daily reading" }
            .prefix(1)
            .sink { _ in observed.fulfill() }
        defer { observation.cancel() }

        let saved = await sut.saveNames(in: [.coral])
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertTrue(saved)
        sut.beginEditing()
        XCTAssertTrue(sut.draftNames.isEmpty)
        XCTAssertEqual(sut.items.first { $0.slot == .coral }?.name, "Daily reading")
    }

    func test_saveNames_untouchedNameDoesNotWriteOrClearIt() async throws {
        try await service.renameReadingBookmark(in: .coral, name: "Daily reading", quran: .hafsMadani1405)
        let original = try await storedBookmark(in: .coral)
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        defer { startTask.cancel() }
        sut.beginEditing()

        let saved = await sut.saveNames(in: ReadingBookmarkSlot.allCases)
        let stored = try await storedBookmark(in: .coral)

        XCTAssertTrue(saved)
        XCTAssertEqual(stored, original)
    }

    func test_saveNames_updatesBookmarkWithoutWaitingForObservation() async throws {
        let sut = makeSUT(target: .ayah(ayah(1)))
        let startTask = await start(sut)
        startTask.cancel()
        await startTask.value
        sut.beginEditing()
        sut.draftNames[.coral] = "Daily reading"

        let saved = await sut.saveNames(in: [.coral])
        let submitted = try await storedBookmark(in: .coral)
        await sut.finishEditing()
        let stored = try await storedBookmark(in: .coral)

        XCTAssertTrue(saved)
        XCTAssertEqual(sut.items.first { $0.slot == .coral }?.name, "Daily reading")
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
