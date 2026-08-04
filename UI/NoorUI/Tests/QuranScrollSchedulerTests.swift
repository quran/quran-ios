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
}
