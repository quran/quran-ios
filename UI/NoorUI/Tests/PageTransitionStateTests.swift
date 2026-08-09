import XCTest
@testable import NoorUI

final class PageTransitionStateTests: XCTestCase {
    func testSelectionAppliesWhenUserTransitionIsIdle() {
        var sut = PageTransitionState<Int>()

        XCTAssertTrue(sut.shouldApply(2))
    }

    func testSelectionIsDeferredDuringUserTransition() {
        var sut = PageTransitionState<Int>()
        _ = sut.userTransitionWillBegin()

        XCTAssertFalse(sut.shouldApply(2))
        XCTAssertTrue(sut.isUserTransitionInProgress)
    }

    func testLatestDeferredSelectionAppliesAfterUserTransition() {
        var sut = PageTransitionState<Int>()
        _ = sut.userTransitionWillBegin()
        _ = sut.shouldApply(2)
        _ = sut.shouldApply(3)

        let selection = sut.userTransitionDidFinish(visibleElement: 1)

        XCTAssertEqual(selection, 3)
        XCTAssertFalse(sut.isUserTransitionInProgress)
    }

    func testVisibleDeferredSelectionIsDiscardedAfterUserTransition() {
        var sut = PageTransitionState<Int>()
        _ = sut.userTransitionWillBegin()
        _ = sut.shouldApply(2)

        XCTAssertNil(sut.userTransitionDidFinish(visibleElement: 2))
    }

    func testSelectionIsDeferredAsSoonAsPagingGestureBegins() {
        var sut = PageTransitionState<Int>()
        XCTAssertTrue(sut.userGestureWillBegin())

        XCTAssertFalse(sut.shouldApply(2))
        XCTAssertTrue(sut.isGestureAwaitingPageTransition)
    }

    func testPageTransitionPreservesSelectionDeferredDuringEarlyGesture() {
        var sut = PageTransitionState<Int>()
        _ = sut.userGestureWillBegin()
        _ = sut.shouldApply(2)

        XCTAssertFalse(sut.userTransitionWillBegin())
        XCTAssertEqual(sut.userTransitionDidFinish(visibleElement: 1), 2)
    }

    func testGestureWithoutPageTransitionReplaysDeferredSelection() {
        var sut = PageTransitionState<Int>()
        _ = sut.userGestureWillBegin()
        _ = sut.shouldApply(2)

        XCTAssertEqual(sut.userGestureDidFinish(visibleElement: 1), 2)
        XCTAssertFalse(sut.isUserTransitionInProgress)
    }

    func testSelectionIsDeferredDuringProgrammaticTransition() {
        var sut = PageTransitionState<Int>()
        sut.programmaticTransitionWillBegin()

        XCTAssertFalse(sut.shouldApply(3))
        XCTAssertEqual(sut.programmaticTransitionDidFinish(visibleElement: 2), 3)
        XCTAssertTrue(sut.shouldApply(3))
    }
}
