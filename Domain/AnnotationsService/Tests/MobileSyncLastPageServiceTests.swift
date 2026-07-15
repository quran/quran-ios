#if QURAN_SYNC
import MobileSyncTestSupport
import QuranKit
import XCTest
@testable import AnnotationsService

final class MobileSyncLastPageServiceTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared
    private var service: MobileSyncLastPageService!

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        service = MobileSyncLastPageService(quranDataService: database.quranDataService)
    }

    override func tearDown() async throws {
        try await database.reset()
        service = nil
        try await super.tearDown()
    }

    func test_add_persistsReadingSessionAndPublishesLastPage() async throws {
        let quran = Quran.hafsMadani1405
        let page = quran.pages[10]
        let published = expectation(description: "Publishes the persisted last page")
        let observation = Task {
            do {
                for try await lastPages in service.lastPages(quran: quran) where lastPages.first?.page == page {
                    published.fulfill()
                    return
                }
            } catch is CancellationError {
                return
            } catch {
                XCTFail("Unexpected observation error: \(error)")
            }
        }
        defer { observation.cancel() }

        let lastPage = try await service.add(page: page)

        XCTAssertEqual(lastPage.page, page)
        XCTAssertNotNil(lastPage.localId)
        await fulfillment(of: [published], timeout: 2)
    }

    func test_update_persistsNewPageOnExistingReadingSession() async throws {
        let quran = Quran.hafsMadani1405
        let original = try await service.add(page: quran.pages[10])

        let updated = try await service.update(lastPage: original, toPage: quran.pages[20])

        XCTAssertEqual(updated.localId, original.localId)
        XCTAssertEqual(updated.page, quran.pages[20])
        let sessions = database.quranDataService.readingSessionsSequence().makeAsyncIterator()
        let storedSessions = try await sessions.next()
        XCTAssertEqual(storedSessions?.count, 1)
        XCTAssertEqual(storedSessions?.first?.id, original.localId)
        XCTAssertEqual(storedSessions?.first?.sura, Int32(quran.pages[20].firstVerse.sura.suraNumber))
        XCTAssertEqual(storedSessions?.first?.ayah, Int32(quran.pages[20].firstVerse.ayah))
    }

    func test_updateCollisionPreservesBothReadingSessions() async throws {
        let quran = Quran.hafsMadani1405
        let source = try await service.add(page: quran.pages[10])
        let destination = try await service.add(page: quran.pages[20])
        let sourceID = try XCTUnwrap(source.localId)
        let destinationID = try XCTUnwrap(destination.localId)

        do {
            _ = try await service.update(lastPage: source, toPage: quran.pages[20])
            XCTFail("Expected the MobileSync collision error")
        } catch is CancellationError {
            XCTFail("Unexpected cancellation")
        } catch {}

        let iterator = database.quranDataService.readingSessionsSequence().makeAsyncIterator()
        let value = try await iterator.next()
        let storedSessions = try XCTUnwrap(value)
        XCTAssertEqual(Set(storedSessions.map(\.id)), Set([sourceID, destinationID]))
    }

    func test_lastPagesObserversCancelIndependently() async throws {
        let quran = Quran.hafsMadani1405
        let firstPage = quran.pages[10]
        let secondPage = quran.pages[20]
        let firstObserverPublished = expectation(description: "First observer publishes")
        let secondObserverPublishedFirstPage = expectation(description: "Second observer publishes first page")
        let secondObserverPublishedSecondPage = expectation(description: "Second observer remains active")
        let firstObservation = Task {
            var published = false
            do {
                for try await lastPages in service.lastPages(quran: quran) {
                    if !published, lastPages.contains(where: { $0.page == firstPage }) {
                        published = true
                        firstObserverPublished.fulfill()
                    }
                }
            } catch is CancellationError {
                return
            } catch {
                XCTFail("Unexpected first-observer error: \(error)")
            }
        }
        let secondObservation = Task {
            var publishedFirstPage = false
            do {
                for try await lastPages in service.lastPages(quran: quran) {
                    if !publishedFirstPage, lastPages.contains(where: { $0.page == firstPage }) {
                        publishedFirstPage = true
                        secondObserverPublishedFirstPage.fulfill()
                    }
                    if lastPages.contains(where: { $0.page == secondPage }) {
                        secondObserverPublishedSecondPage.fulfill()
                        return
                    }
                }
            } catch is CancellationError {
                return
            } catch {
                XCTFail("Unexpected second-observer error: \(error)")
            }
        }
        defer {
            firstObservation.cancel()
            secondObservation.cancel()
        }

        _ = try await service.add(page: firstPage)
        await fulfillment(of: [firstObserverPublished, secondObserverPublishedFirstPage], timeout: 2)
        firstObservation.cancel()
        _ = try await service.add(page: secondPage)

        await fulfillment(of: [secondObserverPublishedSecondPage], timeout: 2)
    }
}
#endif
