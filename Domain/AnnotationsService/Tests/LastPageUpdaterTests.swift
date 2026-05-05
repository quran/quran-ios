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

        await waitUntil { service.addCallCount == 1 }
        XCTAssertEqual(service.addPages, [quran.pages[0]])
        XCTAssertEqual(service.updateCallCount, 0)
    }

    func test_configureWithExistingLastPage_updatesLastPage() async {
        let service = LastPageServiceSpy()
        let sut = LastPageUpdater(service: service)

        sut.configure(initialPage: quran.pages[1], lastPage: quran.pages[0])

        await waitUntil { service.updateCallCount == 1 }
        XCTAssertEqual(service.updateCalls.first?.page, quran.pages[0])
        XCTAssertEqual(service.updateCalls.first?.toPage, quran.pages[1])
        XCTAssertEqual(service.addCallCount, 0)
    }

    private let quran = Quran(raw: Madani1405QuranReadingInfoRawData())

    private func waitUntil(
        timeoutIterations: Int = 100,
        condition: @escaping @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0 ..< timeoutIterations {
            if condition() {
                return
            }
            await Task.yield()
        }
        XCTFail("Condition was not met in time", file: file, line: line)
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

    func update(page: Page, toPage: Page) async throws -> LastPage {
        updateCallCount += 1
        updateCalls.append(UpdateCall(page: page, toPage: toPage))
        return LastPage(page: toPage, createdOn: Date(), modifiedOn: Date())
    }
}
