import XCTest
@testable import NoorUI

final class PageTransitionStateTests: XCTestCase {
    func testSelectionAppliesWhenUserTransitionIsIdle() {
        var sut = PageTransitionState<Int>()

        XCTAssertTrue(sut.shouldApply(2))
    }

    func testSelectionIsDeferredDuringUserTransition() {
        var sut = PageTransitionState<Int>()
        sut.userTransitionWillBegin()

        XCTAssertFalse(sut.shouldApply(2))
        XCTAssertTrue(sut.isUserTransitionInProgress)
    }

    func testLatestDeferredSelectionAppliesAfterUserTransition() {
        var sut = PageTransitionState<Int>()
        sut.userTransitionWillBegin()
        _ = sut.shouldApply(2)
        _ = sut.shouldApply(3)

        let selection = sut.userTransitionDidFinish(visibleElement: 1)

        XCTAssertEqual(selection, 3)
        XCTAssertFalse(sut.isUserTransitionInProgress)
    }

    func testVisibleDeferredSelectionIsDiscardedAfterUserTransition() {
        var sut = PageTransitionState<Int>()
        sut.userTransitionWillBegin()
        _ = sut.shouldApply(2)

        XCTAssertNil(sut.userTransitionDidFinish(visibleElement: 2))
    }
}
