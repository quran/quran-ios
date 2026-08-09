import XCTest
@testable import NoorUI

final class PageTransitionStateTests: XCTestCase {
    func testProgrammaticTransitionStartsWhenIdle() {
        var sut = PageTransitionState<Int>()

        XCTAssertEqual(sut.requestProgrammaticTransition(to: 2), .started)
    }

    func testSelectionIsDeferredDuringUserTransition() {
        var sut = PageTransitionState<Int>()
        XCTAssertEqual(sut.userTransitionWillBegin(), .started)

        XCTAssertEqual(sut.requestProgrammaticTransition(to: 2), .deferred)
        XCTAssertTrue(sut.isUserTransitionInProgress)
    }

    func testLatestDeferredSelectionAppliesAfterUserTransition() {
        var sut = PageTransitionState<Int>()
        _ = sut.userTransitionWillBegin()
        _ = sut.requestProgrammaticTransition(to: 2)
        _ = sut.requestProgrammaticTransition(to: 3)

        let selection = sut.userTransitionDidFinish(visibleElement: 1)

        XCTAssertEqual(selection, 3)
        XCTAssertFalse(sut.isUserTransitionInProgress)
    }

    func testVisibleDeferredSelectionIsDiscardedAfterUserTransition() {
        var sut = PageTransitionState<Int>()
        _ = sut.userTransitionWillBegin()
        _ = sut.requestProgrammaticTransition(to: 2)

        XCTAssertNil(sut.userTransitionDidFinish(visibleElement: 2))
    }

    func testSelectionIsDeferredAsSoonAsPagingGestureBegins() {
        var sut = PageTransitionState<Int>()
        XCTAssertTrue(sut.userGestureWillBegin())

        XCTAssertEqual(sut.requestProgrammaticTransition(to: 2), .deferred)
        XCTAssertTrue(sut.isGestureAwaitingPageTransition)
    }

    func testPageTransitionPreservesSelectionDeferredDuringEarlyGesture() {
        var sut = PageTransitionState<Int>()
        _ = sut.userGestureWillBegin()
        _ = sut.requestProgrammaticTransition(to: 2)

        XCTAssertEqual(sut.userTransitionWillBegin(), .continuedGesture)
        XCTAssertEqual(sut.userTransitionDidFinish(visibleElement: 1), 2)
    }

    func testGestureWithoutPageTransitionReplaysDeferredSelection() {
        var sut = PageTransitionState<Int>()
        _ = sut.userGestureWillBegin()
        _ = sut.requestProgrammaticTransition(to: 2)

        XCTAssertEqual(sut.userGestureDidFinish(visibleElement: 1), 2)
        XCTAssertFalse(sut.isUserTransitionInProgress)
    }

    func testSelectionIsDeferredDuringProgrammaticTransition() {
        var sut = PageTransitionState<Int>()
        XCTAssertEqual(sut.requestProgrammaticTransition(to: 2), .started)

        XCTAssertEqual(sut.requestProgrammaticTransition(to: 3), .deferred)
        XCTAssertEqual(sut.programmaticTransitionDidFinish(visibleElement: 2), 3)
        XCTAssertEqual(sut.requestProgrammaticTransition(to: 3), .started)
    }

    func testUserTransitionIsIgnoredWhileProgrammaticTransitionIsActive() {
        var sut = PageTransitionState<Int>()
        _ = sut.requestProgrammaticTransition(to: 2)

        XCTAssertEqual(sut.userTransitionWillBegin(), .ignored)
    }
}
