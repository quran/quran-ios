import AnnotationsService
import CombineSchedulers
import QuranAnnotations
import QuranKit
import XCTest
@testable import QuranContentFeature

@MainActor
final class NavigationHighlighterTests: XCTestCase {
    func testNavigationSetsTheTargetAndHighlight() {
        sut.navigate(to: verses[0])

        XCTAssertEqual(service.overlays.navigationTarget, verses[0])
        XCTAssertEqual(service.overlays.navigationHighlight, verses[0])
    }

    func testHighlightStaysWhileContentLoadsSlowly() {
        sut.navigate(to: verses[0])

        scheduler.advance(by: .seconds(9))

        XCTAssertEqual(service.overlays.navigationTarget, verses[0])
        XCTAssertEqual(service.overlays.navigationHighlight, verses[0])
    }

    func testHighlightHidesAfterTheDelayFollowingConsumption() {
        sut.navigate(to: verses[0])
        service.overlays.colorHighlights = [verses[0]: .green]

        service.consumeNavigationTarget(verses[0])
        scheduler.advance(by: .milliseconds(1499))

        XCTAssertEqual(service.overlays.navigationHighlight, verses[0])

        scheduler.advance(by: .milliseconds(1))

        XCTAssertNil(service.overlays.navigationHighlight)
        XCTAssertEqual(service.overlays.colorHighlights, [verses[0]: .green])
    }

    func testUnconsumedTargetTimesOut() {
        sut.navigate(to: verses[0])

        scheduler.advance(by: .seconds(10))

        XCTAssertNil(service.overlays.navigationTarget)
        XCTAssertNil(service.overlays.navigationHighlight)
    }

    func testTimeoutKeepsAConsumedNavigationsFade() {
        sut.navigate(to: verses[0])
        scheduler.advance(by: .seconds(9))
        service.consumeNavigationTarget(verses[0])

        scheduler.advance(by: .seconds(1))

        XCTAssertEqual(service.overlays.navigationHighlight, verses[0])

        scheduler.advance(by: .milliseconds(500))

        XCTAssertNil(service.overlays.navigationHighlight)
    }

    func testHideClearsTheHighlightAndTargetAndForgetsTheVerse() {
        sut.navigate(to: verses[0])

        sut.hide()
        sut.rearm()

        XCTAssertNil(service.overlays.navigationHighlight)
        XCTAssertNil(service.overlays.navigationTarget)
    }

    func testRearmScrollsToTheNavigatedVerseAgainWithoutHighlighting() {
        sut.navigate(to: verses[0])
        service.consumeNavigationTarget(verses[0])
        scheduler.advance(by: .seconds(2))
        var scrollCount = 0
        let subscription = service.scrollRequests.sink { scrollCount += 1 }
        defer { subscription.cancel() }

        sut.rearm()

        XCTAssertEqual(service.overlays.navigationTarget, verses[0])
        XCTAssertNil(service.overlays.navigationHighlight)
        XCTAssertEqual(scrollCount, 1)
    }

    func testUnconsumedRearmedTargetTimesOut() {
        sut.navigate(to: verses[0])
        service.consumeNavigationTarget(verses[0])
        scheduler.advance(by: .seconds(2))

        sut.rearm()
        scheduler.advance(by: .seconds(10))

        XCTAssertNil(service.overlays.navigationTarget)
    }

    func testStayingOnTheVersesPageKeepsTheNavigation() {
        let otherPage = Quran.hafsMadani1405.pages[1]
        sut.navigate(to: verses[0])

        sut.visiblePagesChanged(to: [verses[0].page, otherPage])

        XCTAssertEqual(service.overlays.navigationTarget, verses[0])
        XCTAssertEqual(service.overlays.navigationHighlight, verses[0])
    }

    func testLeavingTheVersesPageClearsAndForgetsTheNavigation() {
        sut.navigate(to: verses[0])

        sut.visiblePagesChanged(to: [Quran.hafsMadani1405.pages[1]])
        sut.rearm()
        scheduler.advance(by: .seconds(10))

        XCTAssertNil(service.overlays.navigationTarget)
        XCTAssertNil(service.overlays.navigationHighlight)
    }

    func testNewNavigationRestartsTheHighlight() {
        sut.navigate(to: verses[0])
        service.consumeNavigationTarget(verses[0])
        scheduler.advance(by: .seconds(1))

        sut.navigate(to: verses[1])
        scheduler.advance(by: .seconds(1))

        XCTAssertEqual(service.overlays.navigationHighlight, verses[1])

        service.consumeNavigationTarget(verses[1])
        scheduler.advance(by: .milliseconds(1500))

        XCTAssertNil(service.overlays.navigationHighlight)
    }

    // MARK: Private

    private let verses = Quran.hafsMadani1405.pages[0].verses
    private let service = VerseOverlayService()
    private let scheduler = DispatchQueue.test
    private lazy var sut = NavigationHighlighter(overlayService: service, scheduler: scheduler.eraseToAnyScheduler())
}
