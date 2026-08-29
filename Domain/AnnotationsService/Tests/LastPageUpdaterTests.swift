import Combine
import Foundation
import Utilities
import XCTest
@testable import AnnotationsService
@testable import QuranAnnotations
@testable import QuranKit

@MainActor
final class LastPageUpdaterTests: XCTestCase {
    func test_configureWithInitialPageOnly_createsLastPage() async {
        let service = LastPageServiceSpy()
        let sut = LastPageUpdater(service: service)

        sut.configure(initialPage: quran.pages[0], lastPage: nil)

        await service.waitForNextAdd()
        XCTAssertEqual(service.addPages, [quran.pages[0]])
        XCTAssertEqual(service.updateCallCount, 0)
    }

    func test_configureWithExistingLastPage_updatesLastPage() async {
        let service = LastPageServiceSpy()
        let sut = LastPageUpdater(service: service)

        let lastPage = makeLastPage(page: quran.pages[0])

        sut.configure(initialPage: quran.pages[1], lastPage: lastPage)

        await service.waitForNextUpdate()
        XCTAssertEqual(service.updateCalls.first?.page, quran.pages[0])
        XCTAssertEqual(service.updateCalls.first?.toPage, quran.pages[1])
        XCTAssertEqual(service.addCallCount, 0)
    }

    func test_scrollDuringCreation_updatesCreatedLastPageToLatestPage() async {
        let service = ControllableLastPageService()
        let sut = LastPageUpdater(service: service)

        sut.configure(initialPage: quran.pages[0], lastPage: nil)
        await service.waitForNextAdd()
        sut.updateTo(pages: [quran.pages[1]])

        service.completeNextAdd()
        await service.waitForNextAddCompletion()
        await service.waitForNextUpdate()
        let updateCalls = service.updateCalls
        XCTAssertEqual(updateCalls.first?.page, quran.pages[0])
        XCTAssertEqual(updateCalls.first?.toPage, quran.pages[1])
        service.completeNextUpdate()
        await service.waitForNextUpdateCompletion()
        XCTAssertEqual(sut.lastPage?.page, quran.pages[1])
        assertIdentity(sut.lastPage, syncID: "created-last-page", noSyncPage: quran.pages[1])
    }

    func test_rapidScrolling_serializesWritesAndCoalescesLatestPage() async {
        let service = ControllableLastPageService()
        let sut = LastPageUpdater(service: service)
        let lastPage = makeLastPage(page: quran.pages[0])

        sut.configure(initialPage: quran.pages[1], lastPage: lastPage)
        await service.waitForNextUpdate()
        sut.updateTo(pages: [quran.pages[2]])
        sut.updateTo(pages: [quran.pages[3]])
        let callsWhileFirstUpdateIsPending = service.updateCalls
        XCTAssertEqual(callsWhileFirstUpdateIsPending.count, 1)

        service.completeNextUpdate()
        await service.waitForNextUpdateCompletion()
        await service.waitForNextUpdate()
        let updateCalls = service.updateCalls
        XCTAssertEqual(updateCalls[1].page, quran.pages[1])
        XCTAssertEqual(updateCalls[1].toPage, quran.pages[3])
        service.completeNextUpdate()
        await service.waitForNextUpdateCompletion()
        XCTAssertEqual(sut.lastPage?.page, quran.pages[3])
        assertIdentity(sut.lastPage, syncID: "last-page", noSyncPage: quran.pages[3])
    }

    func test_scrollBackToInFlightPage_doesNotCreateRedundantWrite() async {
        let service = ControllableLastPageService()
        let sut = LastPageUpdater(service: service)
        let lastPage = makeLastPage(page: quran.pages[0])

        sut.configure(initialPage: quran.pages[1], lastPage: lastPage)
        await service.waitForNextUpdate()
        sut.updateTo(pages: [quran.pages[2]])
        sut.updateTo(pages: [quran.pages[1]])

        service.completeNextUpdate()
        await service.waitForNextUpdateCompletion()
        XCTAssertEqual(sut.lastPage?.page, quran.pages[1])
        let updateCalls = service.updateCalls
        XCTAssertEqual(updateCalls.count, 1)
    }

    func test_updateToConfiguredPageBeforeWriteStarts_preservesConfigurationWrite() async {
        let service = ControllableLastPageService()
        let sut = LastPageUpdater(service: service)
        let lastPage = makeLastPage(page: quran.pages[0])

        sut.configure(initialPage: quran.pages[0], lastPage: lastPage)
        sut.updateTo(pages: [quran.pages[0]])

        await service.waitForNextUpdate()
        let updateCalls = service.updateCalls
        XCTAssertEqual(updateCalls.first?.page, quran.pages[0])
        XCTAssertEqual(updateCalls.first?.toPage, quran.pages[0])
    }

    func test_scrollBackToCurrentPageWhileUpdateIsInFlight_updatesBackToCurrentPage() async {
        let service = ControllableLastPageService()
        let sut = LastPageUpdater(service: service)
        let lastPage = makeLastPage(page: quran.pages[0])

        sut.configure(initialPage: quran.pages[1], lastPage: lastPage)
        await service.waitForNextUpdate()
        sut.updateTo(pages: [quran.pages[0]])

        service.completeNextUpdate()
        await service.waitForNextUpdateCompletion()
        await service.waitForNextUpdate()
        let updateCalls = service.updateCalls
        XCTAssertEqual(updateCalls[1].page, quran.pages[1])
        XCTAssertEqual(updateCalls[1].toPage, quran.pages[0])

        service.completeNextUpdate()
        await service.waitForNextUpdateCompletion()
        XCTAssertEqual(sut.lastPage?.page, quran.pages[0])
    }

    func test_reconfigure_discardsInFlightResultBeforeStartingNewWrite() async {
        let service = ControllableLastPageService()
        let sut = LastPageUpdater(service: service)

        sut.configure(initialPage: quran.pages[1], lastPage: makeLastPage(page: quran.pages[0], id: "old-session"))
        await service.waitForNextUpdate()
        sut.configure(initialPage: quran.pages[11], lastPage: makeLastPage(page: quran.pages[10], id: "new-session"))
        let callsWhileFirstUpdateIsPending = service.updateCalls
        XCTAssertEqual(callsWhileFirstUpdateIsPending.count, 1)

        service.completeNextUpdate()
        await service.waitForNextUpdateCompletion()
        await service.waitForNextUpdate()
        let updateCalls = service.updateCalls
        XCTAssertEqual(updateCalls[1].page, quran.pages[10])
        XCTAssertEqual(updateCalls[1].toPage, quran.pages[11])
        XCTAssertEqual(sut.lastPage?.page, quran.pages[10])
        assertIdentity(sut.lastPage, syncID: "new-session", noSyncPage: quran.pages[10])
        service.completeNextUpdate()
        await service.waitForNextUpdateCompletion()
        XCTAssertEqual(sut.lastPage?.page, quran.pages[11])
        assertIdentity(sut.lastPage, syncID: "new-session", noSyncPage: quran.pages[11])
    }

    func test_deinit_cancelsInFlightWrite() async {
        let service = ControllableLastPageService()
        weak var weakSUT: LastPageUpdater?

        do {
            let sut = LastPageUpdater(service: service)
            weakSUT = sut
            sut.configure(initialPage: quran.pages[0], lastPage: nil)
            await service.waitForNextAdd()
        }

        await service.waitForNextCancellation()
        XCTAssertNil(weakSUT)
        XCTAssertEqual(service.cancellationCount, 1)
    }

    private let quran = Quran.hafsMadani1405

    private func makeLastPage(page: Page, id: String = "last-page") -> LastPage {
        makeTestLastPage(page: page, syncID: id)
    }
}

@MainActor
private final class ControllableLastPageService: LastPageService {
    struct UpdateCall: Equatable {
        let page: Page
        let toPage: Page
    }

    private(set) var addPages: [Page] = []
    private(set) var updateCalls: [UpdateCall] = []
    private(set) var cancellationCount = 0

    func waitForNextAdd() async {
        await addStarted.wait()
    }

    func waitForNextAddCompletion() async {
        await addCompleted.wait()
    }

    func waitForNextUpdate() async {
        await updateStarted.wait()
    }

    func waitForNextUpdateCompletion() async {
        await updateCompleted.wait()
    }

    func waitForNextCancellation() async {
        await cancelled.wait()
    }

    func lastPages(quran _: Quran) -> AnyAsyncSequence<[LastPage]> {
        .init(Just<[LastPage]>([]).values)
    }

    func add(page: Page) async throws -> LastPage {
        addPages.append(page)
        defer {
            Task { @MainActor [addCompleted] in
                addCompleted.signal()
            }
        }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pendingAdds.append((page, continuation))
                addStarted.signal()
            }
        } onCancel: {
            Task { @MainActor in
                self.cancelPendingOperation()
            }
        }
    }

    func update(lastPage: LastPage, toPage: Page) async throws -> LastPage {
        updateCalls.append(UpdateCall(page: lastPage.page, toPage: toPage))
        defer {
            Task { @MainActor [updateCompleted] in
                updateCompleted.signal()
            }
        }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pendingUpdates.append((lastPage, toPage, continuation))
                updateStarted.signal()
            }
        } onCancel: {
            Task { @MainActor in
                self.cancelPendingOperation()
            }
        }
    }

    func completeNextAdd() {
        let pending = pendingAdds.removeFirst()
        pending.continuation.resume(returning: makeTestLastPage(page: pending.page, syncID: "created-last-page"))
    }

    func completeNextUpdate() {
        let pending = pendingUpdates.removeFirst()
        pending.continuation.resume(returning: updatedLastPage(pending.lastPage, page: pending.page))
    }

    private typealias PendingAdd = (
        page: Page,
        continuation: CheckedContinuation<LastPage, Error>
    )
    private typealias PendingUpdate = (
        lastPage: LastPage,
        page: Page,
        continuation: CheckedContinuation<LastPage, Error>
    )

    private var pendingAdds: [PendingAdd] = []
    private var pendingUpdates: [PendingUpdate] = []
    private let addStarted = TestSignal()
    private let addCompleted = TestSignal()
    private let updateStarted = TestSignal()
    private let updateCompleted = TestSignal()
    private let cancelled = TestSignal()

    private func cancelPendingOperation() {
        cancellationCount += 1
        cancelled.signal()
        if !pendingAdds.isEmpty {
            pendingAdds.removeFirst().continuation.resume(throwing: CancellationError())
        } else if !pendingUpdates.isEmpty {
            pendingUpdates.removeFirst().continuation.resume(throwing: CancellationError())
        }
    }
}

@MainActor
private final class LastPageServiceSpy: LastPageService {
    struct UpdateCall: Equatable {
        let page: Page
        let toPage: Page
    }

    var addCallCount = 0
    var updateCallCount = 0
    private(set) var addPages: [Page] = []
    private(set) var updateCalls: [UpdateCall] = []

    func waitForNextAdd() async {
        await addStarted.wait()
    }

    func waitForNextUpdate() async {
        await updateStarted.wait()
    }

    func lastPages(quran _: Quran) -> AnyAsyncSequence<[LastPage]> {
        .init(Just<[LastPage]>([]).values)
    }

    func add(page: Page) async throws -> LastPage {
        addCallCount += 1
        addPages.append(page)
        addStarted.signal()
        return makeTestLastPage(page: page, syncID: "created-last-page")
    }

    func update(lastPage: LastPage, toPage: Page) async throws -> LastPage {
        updateCallCount += 1
        updateCalls.append(UpdateCall(page: lastPage.page, toPage: toPage))
        updateStarted.signal()
        return updatedLastPage(lastPage, page: toPage)
    }

    private let addStarted = TestSignal()
    private let updateStarted = TestSignal()
}

@MainActor
private final class TestSignal {
    func signal() {
        guard !waiters.isEmpty else {
            bufferedSignals += 1
            return
        }
        waiters.removeFirst().resume()
    }

    func wait() async {
        guard bufferedSignals == 0 else {
            bufferedSignals -= 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    private var bufferedSignals = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []
}

private func makeTestLastPage(page: Page, syncID: String) -> LastPage {
    #if QURAN_SYNC
    LastPage(id: syncID, page: page, modifiedOn: Date())
    #else
    LastPage(page: page, createdOn: Date(), modifiedOn: Date())
    #endif
}

private func updatedLastPage(_ lastPage: LastPage, page: Page) -> LastPage {
    #if QURAN_SYNC
    LastPage(id: lastPage.id, page: page, modifiedOn: Date())
    #else
    LastPage(page: page, createdOn: lastPage.createdOn, modifiedOn: Date())
    #endif
}

private func assertIdentity(
    _ lastPage: LastPage?,
    syncID: String,
    noSyncPage: Page,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    #if QURAN_SYNC
    XCTAssertEqual(lastPage?.id, syncID, file: file, line: line)
    #else
    XCTAssertEqual(lastPage?.id, noSyncPage, file: file, line: line)
    #endif
}
