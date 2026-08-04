import XCTest
@testable import NoorUI

final class ItemDeletionTrackerTests: XCTestCase {
    func test_beginDeletingRejectsDuplicateUntilDeletionFinishes() {
        var tracker = ItemDeletionTracker<Int>()

        XCTAssertTrue(tracker.beginDeleting(1))
        XCTAssertFalse(tracker.beginDeleting(1))

        tracker.finishDeleting(1)

        XCTAssertTrue(tracker.beginDeleting(1))
    }
}
