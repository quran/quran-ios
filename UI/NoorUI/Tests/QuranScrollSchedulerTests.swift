import XCTest
@testable import NoorUI

@MainActor
final class QuranScrollSchedulerTests: XCTestCase {
    func testSchedulingNewScrollCancelsPendingScroll() async {
        let scheduler = QuranScrollScheduler<Int>()
        let staleScroll = expectation(description: "Stale scroll is cancelled")
        staleScroll.isInverted = true
        let latestScroll = expectation(description: "Latest scroll runs")

        scheduler.schedule {
            staleScroll.fulfill()
        }
        scheduler.schedule {
            latestScroll.fulfill()
        }

        await fulfillment(of: [latestScroll, staleScroll], timeout: 0.1)
    }

    func testRemovingScrollTargetCancelsPendingScroll() async {
        let scheduler = QuranScrollScheduler<Int>()
        let staleScroll = expectation(description: "Stale scroll is cancelled")
        staleScroll.isInverted = true

        scheduler.scroll(to: 1) { _ in
            staleScroll.fulfill()
        }
        scheduler.scroll(to: nil) { _ in
            XCTFail("A removed target must not scroll")
        }

        await fulfillment(of: [staleScroll], timeout: 0.1)
        XCTAssertNil(scheduler.target)
    }

    func testScrollRecordsTargetAndScrollsToIt() async {
        let scheduler = QuranScrollScheduler<Int>()
        let scroll = expectation(description: "Target scrolls")
        var scrolledTarget: Int?

        scheduler.scroll(to: 2) {
            scrolledTarget = $0
            scroll.fulfill()
        }

        // Size changes re-scroll to the recorded target.
        XCTAssertEqual(scheduler.target, 2)
        await fulfillment(of: [scroll], timeout: 0.1)
        XCTAssertEqual(scrolledTarget, 2)
    }
}
