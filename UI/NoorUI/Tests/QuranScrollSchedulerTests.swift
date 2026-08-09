import XCTest
@testable import NoorUI

@MainActor
final class QuranScrollSchedulerTests: XCTestCase {
    func testSchedulingNewScrollCancelsPendingScroll() async {
        let scheduler = QuranScrollScheduler()
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
        let scheduler = QuranScrollScheduler()
        let staleScroll = expectation(description: "Stale scroll is cancelled")
        staleScroll.isInverted = true

        scheduler.scheduleScroll(to: 1, transform: { $0 }) { _ in
            staleScroll.fulfill()
        }
        scheduler.scheduleScroll(to: nil as Int?, transform: { $0 }) { _ in
            XCTFail("A removed target must not scroll")
        }

        await fulfillment(of: [staleScroll], timeout: 0.1)
    }

    func testInvalidScrollTargetDoesNotRunAction() async {
        let scheduler = QuranScrollScheduler()
        let invalidScroll = expectation(description: "Invalid scroll does not run")
        invalidScroll.isInverted = true

        scheduler.scheduleScroll(to: 1, transform: { _ in nil as Int? }) { _ in
            invalidScroll.fulfill()
        }

        await fulfillment(of: [invalidScroll], timeout: 0.1)
    }
}
