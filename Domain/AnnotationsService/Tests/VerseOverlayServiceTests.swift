import Combine
import QuranAnnotations
import QuranKit
import XCTest
@testable import AnnotationsService

@MainActor
final class VerseOverlayServiceTests: XCTestCase {
    func test_pageSubscription_ignoresChangesToOtherPages() {
        let page = Quran.hafsMadani1405.pages[0]
        let other = Quran.hafsMadani1405.pages[1].firstVerse
        let service = VerseOverlayService()
        var received: [VerseOverlays] = []
        let subscription = service.$overlays
            .map { $0.restricted(to: page) }
            .removeDuplicates()
            .sink { received.append($0) }
        defer { subscription.cancel() }

        service.overlays.notedVerses = [other]
        service.overlays.colorHighlights = [other: .green]
        service.overlays.selectedVerses = [other]
        service.overlays.pointedWord = Word(verse: other, wordNumber: 1)

        XCTAssertEqual(received, [VerseOverlays()])

        service.overlays.notedVerses.insert(page.firstVerse)

        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received.last?.notedVerses, [page.firstVerse])
    }

    func test_visibilityChanges_reachEveryPageSubscription() {
        let pages = Array(Quran.hafsMadani1405.pages.prefix(2))
        let service = VerseOverlayService()
        var visibilityByPage: [Page: [Bool]] = [:]
        let subscriptions = pages.map { page in
            service.$overlays
                .map { $0.restricted(to: page) }
                .removeDuplicates()
                .sink { visibilityByPage[page, default: []].append($0.annotationsHidden) }
        }
        defer { subscriptions.forEach { $0.cancel() } }

        service.overlays.annotationsHidden = true
        service.overlays.annotationsHidden = true
        service.overlays.annotationsHidden = false

        for page in pages {
            XCTAssertEqual(visibilityByPage[page], [false, true, false])
        }
    }

    func test_newPageSubscription_receivesCurrentVisibility() {
        let service = VerseOverlayService()
        service.overlays.annotationsHidden = true
        var received: [Bool] = []

        let subscription = service.$overlays
            .map { $0.restricted(to: Quran.hafsMadani1405.pages[1]) }
            .removeDuplicates()
            .sink { received.append($0.annotationsHidden) }
        defer { subscription.cancel() }

        XCTAssertEqual(received, [true])
    }

    func test_scrollRequests_includeNavigationOutsideTheObservedPage() {
        let service = VerseOverlayService()
        let page = Quran.hafsMadani1405.pages[0]
        let target = Quran.hafsMadani1405.pages[1].firstVerse
        var pageValues: [VerseOverlays] = []
        var scrollCount = 0
        let pageSubscription = service.$overlays
            .map { $0.restricted(to: page) }
            .removeDuplicates()
            .sink { pageValues.append($0) }
        let scrollSubscription = service.scrollRequests.sink { scrollCount += 1 }
        defer {
            pageSubscription.cancel()
            scrollSubscription.cancel()
        }

        service.overlays.navigationTarget = target

        XCTAssertEqual(scrollCount, 1)
        XCTAssertEqual(pageValues, [VerseOverlays()])
        XCTAssertEqual(service.overlays.firstScrollingVerse(), target)
    }

    func test_scrollRequests_preservePlaybackAndNavigationTriggers() {
        let service = VerseOverlayService()
        let verses = Quran.hafsMadani1405.pages[0].verses
        var scrollCount = 0
        let subscription = service.scrollRequests.sink { scrollCount += 1 }
        defer { subscription.cancel() }

        service.overlays.navigationTarget = verses[0]
        service.overlays.navigationTarget = verses[0]
        service.overlays.playingVerses = [verses[1]]
        service.overlays.playingVerses = []
        service.overlays.navigationTarget = nil

        XCTAssertEqual(scrollCount, 4)
    }

    func test_annotationVisibilityAndSelectionChanges_doNotRequestScrolling() {
        let service = VerseOverlayService()
        let verse = Quran.hafsMadani1405.pages[0].firstVerse
        var scrollCount = 0
        let subscription = service.scrollRequests.sink { scrollCount += 1 }
        defer { subscription.cancel() }

        service.overlays.annotationsHidden = true
        service.overlays.annotationsHidden = false
        service.overlays.notedVerses = [verse]
        service.overlays.colorHighlights = [verse: .green]
        service.overlays.selectedVerses = [verse]
        service.overlays.pointedWord = Word(verse: verse, wordNumber: 1)

        XCTAssertEqual(scrollCount, 0)
    }
}
