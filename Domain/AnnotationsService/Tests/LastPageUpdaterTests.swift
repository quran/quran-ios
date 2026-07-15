import Combine
import Foundation
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

        await waitUntil { service.addPages == [self.quran.pages[0]] }
        XCTAssertEqual(service.addPages, [quran.pages[0]])
        XCTAssertEqual(service.updateCallCount, 0)
    }

    func test_configureWithExistingLastPage_updatesLastPage() async {
        let service = LastPageServiceSpy()
        let sut = LastPageUpdater(service: service)

        let lastPage = LastPage(page: quran.pages[0], createdOn: Date(), modifiedOn: Date())

        sut.configure(initialPage: quran.pages[1], lastPage: lastPage)

        await waitUntil { service.updateCalls.first?.page == self.quran.pages[0] }
        XCTAssertEqual(service.updateCalls.first?.page, quran.pages[0])
        XCTAssertEqual(service.updateCalls.first?.toPage, quran.pages[1])
        XCTAssertEqual(service.addCallCount, 0)
    }

    func test_scrollDuringCreation_updatesCreatedLastPageToLatestPage() async {
        let service = ControllableLastPageService()
        let sut = LastPageUpdater(service: service)

        sut.configure(initialPage: quran.pages[0], lastPage: nil)
        await waitUntil { await service.addPages == [self.quran.pages[0]] }
        sut.updateTo(pages: [quran.pages[1]])

        await service.completeNextAdd()
        await waitUntil { await service.updateCalls.count == 1 }
        let updateCalls = await service.updateCalls
        XCTAssertEqual(updateCalls.first?.page, quran.pages[0])
        XCTAssertEqual(updateCalls.first?.toPage, quran.pages[1])
        await service.completeNextUpdate()
        await waitUntil { sut.lastPage?.page == self.quran.pages[1] }
    }

    func test_rapidScrolling_serializesWritesAndCoalescesLatestPage() async {
        let service = ControllableLastPageService()
        let sut = LastPageUpdater(service: service)
        let lastPage = makeLastPage(page: quran.pages[0])

        sut.configure(initialPage: quran.pages[1], lastPage: lastPage)
        await waitUntil { await service.updateCalls.count == 1 }
        sut.updateTo(pages: [quran.pages[2]])
        sut.updateTo(pages: [quran.pages[3]])
        let callsWhileFirstUpdateIsPending = await service.updateCalls
        XCTAssertEqual(callsWhileFirstUpdateIsPending.count, 1)

        await service.completeNextUpdate()
        await waitUntil { await service.updateCalls.count == 2 }
        let updateCalls = await service.updateCalls
        XCTAssertEqual(updateCalls[1].page, quran.pages[1])
        XCTAssertEqual(updateCalls[1].toPage, quran.pages[3])
        await service.completeNextUpdate()
        await waitUntil { sut.lastPage?.page == self.quran.pages[3] }
    }

    func test_scrollBackToInFlightPage_doesNotCreateRedundantWrite() async {
        let service = ControllableLastPageService()
        let sut = LastPageUpdater(service: service)
        let lastPage = makeLastPage(page: quran.pages[0])

        sut.configure(initialPage: quran.pages[1], lastPage: lastPage)
        await waitUntil { await service.updateCalls.count == 1 }
        sut.updateTo(pages: [quran.pages[2]])
        sut.updateTo(pages: [quran.pages[1]])

        await service.completeNextUpdate()
        await waitUntil { sut.lastPage?.page == self.quran.pages[1] }
        for _ in 0 ..< 10 {
            await Task.yield()
        }
        let updateCalls = await service.updateCalls
        XCTAssertEqual(updateCalls.count, 1)
    }

    func test_updateToConfiguredPageBeforeWriteStarts_preservesConfigurationWrite() async {
        let service = ControllableLastPageService()
        let sut = LastPageUpdater(service: service)
        let lastPage = makeLastPage(page: quran.pages[0])

        sut.configure(initialPage: quran.pages[0], lastPage: lastPage)
        sut.updateTo(pages: [quran.pages[0]])

        await waitUntil { await service.updateCalls.count == 1 }
        let updateCalls = await service.updateCalls
        XCTAssertEqual(updateCalls.first?.page, quran.pages[0])
        XCTAssertEqual(updateCalls.first?.toPage, quran.pages[0])
    }

    func test_scrollBackToCurrentPageWhileUpdateIsInFlight_updatesBackToCurrentPage() async {
        let service = ControllableLastPageService()
        let sut = LastPageUpdater(service: service)
        let lastPage = makeLastPage(page: quran.pages[0])

        sut.configure(initialPage: quran.pages[1], lastPage: lastPage)
        await waitUntil { await service.updateCalls.count == 1 }
        sut.updateTo(pages: [quran.pages[0]])

        await service.completeNextUpdate()
        await waitUntil { await service.updateCalls.count == 2 }
        let updateCalls = await service.updateCalls
        XCTAssertEqual(updateCalls[1].page, quran.pages[1])
        XCTAssertEqual(updateCalls[1].toPage, quran.pages[0])

        await service.completeNextUpdate()
        await waitUntil { sut.lastPage?.page == self.quran.pages[0] }
    }

    func test_reconfigure_discardsInFlightResultBeforeStartingNewWrite() async {
        let service = ControllableLastPageService()
        let sut = LastPageUpdater(service: service)

        sut.configure(initialPage: quran.pages[1], lastPage: makeLastPage(page: quran.pages[0]))
        await waitUntil { await service.updateCalls.count == 1 }
        sut.configure(initialPage: quran.pages[11], lastPage: makeLastPage(page: quran.pages[10]))
        let callsWhileFirstUpdateIsPending = await service.updateCalls
        XCTAssertEqual(callsWhileFirstUpdateIsPending.count, 1)

        await service.completeNextUpdate()
        await waitUntil { await service.updateCalls.count == 2 }
        let updateCalls = await service.updateCalls
        XCTAssertEqual(updateCalls[1].page, quran.pages[10])
        XCTAssertEqual(updateCalls[1].toPage, quran.pages[11])
        XCTAssertEqual(sut.lastPage?.page, quran.pages[10])
        await service.completeNextUpdate()
        await waitUntil { sut.lastPage?.page == self.quran.pages[11] }
    }

    func test_deinit_cancelsInFlightWrite() async {
        let service = ControllableLastPageService()
        weak var weakSUT: LastPageUpdater?

        do {
            let sut = LastPageUpdater(service: service)
            weakSUT = sut
            sut.configure(initialPage: quran.pages[0], lastPage: nil)
            await waitUntil { await service.addPages.count == 1 }
        }

        await waitUntil { weakSUT == nil }
        await waitUntil { await service.cancellationCount == 1 }
    }

    private let quran = Quran(raw: Madani1405QuranReadingInfoRawData())

    private func makeLastPage(page: Page) -> LastPage {
        LastPage(page: page, createdOn: Date(), modifiedOn: Date())
    }

    private func waitUntil(
        timeoutIterations: Int = 100,
        condition: @escaping @MainActor () async -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0 ..< timeoutIterations {
            if await condition() {
                return
            }
            await Task.yield()
        }
        XCTFail("Condition was not met in time", file: file, line: line)
    }
}

private actor ControllableLastPageService: LastPageService {
    struct UpdateCall: Equatable {
        let page: Page
        let toPage: Page
    }

    private(set) var addPages: [Page] = []
    private(set) var updateCalls: [UpdateCall] = []
    private(set) var cancellationCount = 0

    nonisolated func lastPages(quran _: Quran) -> AnyPublisher<[LastPage], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func add(page: Page) async throws -> LastPage {
        addPages.append(page)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pendingAdds.append((page, continuation))
            }
        } onCancel: {
            Task { await self.cancelPendingOperation() }
        }
    }

    func update(lastPage: LastPage, toPage: Page) async throws -> LastPage {
        updateCalls.append(UpdateCall(page: lastPage.page, toPage: toPage))
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pendingUpdates.append((toPage, continuation))
            }
        } onCancel: {
            Task { await self.cancelPendingOperation() }
        }
    }

    func completeNextAdd() {
        let pending = pendingAdds.removeFirst()
        pending.continuation.resume(returning: makeLastPage(page: pending.page))
    }

    func completeNextUpdate() {
        let pending = pendingUpdates.removeFirst()
        pending.continuation.resume(returning: makeLastPage(page: pending.page))
    }

    private typealias PendingOperation = (
        page: Page,
        continuation: CheckedContinuation<LastPage, Error>
    )

    private var pendingAdds: [PendingOperation] = []
    private var pendingUpdates: [PendingOperation] = []

    private func cancelPendingOperation() {
        cancellationCount += 1
        if !pendingAdds.isEmpty {
            pendingAdds.removeFirst().continuation.resume(throwing: CancellationError())
        } else if !pendingUpdates.isEmpty {
            pendingUpdates.removeFirst().continuation.resume(throwing: CancellationError())
        }
    }

    private func makeLastPage(page: Page) -> LastPage {
        LastPage(page: page, createdOn: Date(), modifiedOn: Date())
    }
}

private final class LastPageServiceSpy: LastPageService {
    struct UpdateCall: Equatable {
        let page: Page
        let toPage: Page
    }

    var addCallCount = 0
    var updateCallCount = 0
    private(set) var addPages: [Page] = []
    private(set) var updateCalls: [UpdateCall] = []

    func lastPages(quran _: Quran) -> AnyPublisher<[LastPage], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func add(page: Page) async throws -> LastPage {
        addCallCount += 1
        addPages.append(page)
        return LastPage(page: page, createdOn: Date(), modifiedOn: Date())
    }

    func update(lastPage: LastPage, toPage: Page) async throws -> LastPage {
        updateCallCount += 1
        updateCalls.append(UpdateCall(page: lastPage.page, toPage: toPage))
        return LastPage(page: toPage, createdOn: Date(), modifiedOn: Date())
    }
}
