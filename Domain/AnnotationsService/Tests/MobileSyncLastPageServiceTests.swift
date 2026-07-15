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
        XCTAssertFalse(lastPage.id.isEmpty)
        await fulfillment(of: [published], timeout: 2)
    }

    func test_update_persistsNewPageOnExistingReadingSession() async throws {
        let quran = Quran.hafsMadani1405
        let original = try await service.add(page: quran.pages[10])

        let updated = try await service.update(lastPage: original, toPage: quran.pages[20])

        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.page, quran.pages[20])
        let sessions = database.quranDataService.readingSessionsSequence().makeAsyncIterator()
        let storedSessions = try await sessions.next()
        XCTAssertEqual(storedSessions?.count, 1)
        XCTAssertEqual(storedSessions?.first?.id, original.id)
        XCTAssertEqual(storedSessions?.first?.sura, Int32(quran.pages[20].firstVerse.sura.suraNumber))
        XCTAssertEqual(storedSessions?.first?.ayah, Int32(quran.pages[20].firstVerse.ayah))
    }

    func test_updateAdvancesModificationTime() async throws {
        let quran = Quran.hafsMadani1405
        let originalPage = quran.pages[10]
        let originalVerse = originalPage.firstVerse
        let originalSession = try await database.quranDataService.addReadingSession(
            sura: Int32(originalVerse.sura.suraNumber),
            ayah: Int32(originalVerse.ayah),
            timestamp: Date(timeIntervalSince1970: 1)
        )
        var iterator = service.lastPages(quran: quran).makeAsyncIterator()
        let originalValue = try await iterator.next()
        let original = try XCTUnwrap(originalValue?.first)

        let updated = try await service.update(lastPage: original, toPage: quran.pages[20])

        XCTAssertEqual(updated.id, originalSession.id)
        XCTAssertGreaterThan(updated.modifiedOn, original.modifiedOn)
    }

    func test_updateCollisionPreservesBothReadingSessions() async throws {
        let quran = Quran.hafsMadani1405
        let source = try await service.add(page: quran.pages[10])
        let destination = try await service.add(page: quran.pages[20])

        do {
            _ = try await service.update(lastPage: source, toPage: quran.pages[20])
            XCTFail("Expected the MobileSync collision error")
        } catch is CancellationError {
            XCTFail("Unexpected cancellation")
        } catch {}

        let iterator = database.quranDataService.readingSessionsSequence().makeAsyncIterator()
        let value = try await iterator.next()
        let storedSessions = try XCTUnwrap(value)
        XCTAssertEqual(Set(storedSessions.map(\.id)), Set([source.id, destination.id]))
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

    func test_lastPagesUsesSessionIdentityForSessionsOnSamePage() async throws {
        let quran = Quran.hafsMadani1405
        let page = quran.pages[10]
        let verses = page.verses
        XCTAssertGreaterThan(verses.count, 1)
        let first = try await database.quranDataService.addReadingSession(
            sura: Int32(verses[0].sura.suraNumber),
            ayah: Int32(verses[0].ayah),
            timestamp: Date(timeIntervalSince1970: 1)
        )
        let second = try await database.quranDataService.addReadingSession(
            sura: Int32(verses[1].sura.suraNumber),
            ayah: Int32(verses[1].ayah),
            timestamp: Date(timeIntervalSince1970: 2)
        )
        var iterator = service.lastPages(quran: quran).makeAsyncIterator()

        let lastPages = try await iterator.next()

        XCTAssertEqual(lastPages?.map(\.page), [page, page])
        XCTAssertEqual(Set(lastPages?.map(\.id) ?? []), Set([first.id, second.id]))
    }

    func test_lastPagesMapsCoordinatesInRequestedQuran() async throws {
        let sura: Int32 = 2
        let ayah: Int32 = 255
        let session = try await database.quranDataService.addReadingSession(
            sura: sura,
            ayah: ayah,
            timestamp: Date(timeIntervalSince1970: 1)
        )

        for quran in [Quran.hafsMadani1405, .hafsMadani1440, .hafsNaskh] {
            var iterator = service.lastPages(quran: quran).makeAsyncIterator()

            let lastPages = try await iterator.next()
            let expectedAyah = try XCTUnwrap(
                AyahNumber(quran: quran, sura: Int(sura), ayah: Int(ayah))
            )

            XCTAssertEqual(lastPages?.map(\.id), [session.id])
            XCTAssertEqual(lastPages?.map(\.page), [expectedAyah.page])
        }
    }

    func test_lastPagesFiltersInvalidCoordinates() async throws {
        _ = try await database.quranDataService.addReadingSession(
            sura: 999,
            ayah: 999,
            timestamp: Date(timeIntervalSince1970: 1)
        )
        var iterator = service.lastPages(quran: .hafsMadani1405).makeAsyncIterator()

        let lastPages = try await iterator.next()

        XCTAssertEqual(lastPages, [])
    }

    func test_lastPagesSortsByModificationTimeThenIdentityAndLimitsToThree() async throws {
        let quran = Quran.hafsMadani1405
        let pages = [10, 20, 30, 40].map { quran.pages[$0] }
        let timestamps = [3.0, 5.0, 5.0, 1.0].map(Date.init(timeIntervalSince1970:))
        var sessionIds: [String] = []
        for (page, timestamp) in zip(pages, timestamps) {
            let verse = page.firstVerse
            let session = try await database.quranDataService.addReadingSession(
                sura: Int32(verse.sura.suraNumber),
                ayah: Int32(verse.ayah),
                timestamp: timestamp
            )
            sessionIds.append(session.id)
        }
        var iterator = service.lastPages(quran: quran).makeAsyncIterator()

        let value = try await iterator.next()
        let lastPages = try XCTUnwrap(value)
        let tiedSessionIds = [sessionIds[1], sessionIds[2]].sorted()

        XCTAssertEqual(lastPages.map(\.id), tiedSessionIds + [sessionIds[0]])
        XCTAssertEqual(lastPages.map(\.modifiedOn), [timestamps[1], timestamps[2], timestamps[0]])
    }
}
#endif
