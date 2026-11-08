import XCTest
@testable import NoorUI

final class ToastQueueTests: XCTestCase {
    func testDismissingAnotherToastLeavesTheShowingToastShowing() {
        // The audio banner dismisses its own toasts when the reader closes, while another feature's toast shows.
        let signInNudge = Toast("Collection created")
        let bannerToast = Toast("Playing")
        var queue = ToastQueue<String>()
        queue.append(signInNudge, in: "reader")
        _ = queue.showNext()

        let dismissesShowing = queue.removeToast(id: bannerToast.id)

        XCTAssertFalse(dismissesShowing)
        XCTAssertEqual(queue.showing?.toast.id, signInNudge.id)
    }

    func testDismissingAWaitingToastDropsIt() {
        let showing = Toast("Collection created")
        let downloading = Toast("Downloading")
        let playing = Toast("Playing")
        var queue = ToastQueue<String>()
        queue.append(showing, in: "reader")
        queue.append(downloading, in: "reader")
        queue.append(playing, in: "reader")
        _ = queue.showNext()

        let dismissesShowing = queue.removeToast(id: downloading.id)
        queue.removeShowing()

        XCTAssertFalse(dismissesShowing)
        XCTAssertEqual(queue.showNext()?.toast.id, playing.id)
    }

    func testDismissingTheShowingToastShowsTheNextOnceItsGone() {
        let playing = Toast("Playing")
        let next = Toast("Collection created")
        var queue = ToastQueue<String>()
        queue.append(playing, in: "reader")
        queue.append(next, in: "bookmarks")
        _ = queue.showNext()

        let dismissesShowing = queue.removeToast(id: playing.id)

        XCTAssertTrue(dismissesShowing)
        XCTAssertNil(queue.showNext(), "The dismissed toast shows until it animates away.")
        queue.removeShowing()
        let shown = queue.showNext()
        XCTAssertEqual(shown?.toast.id, next.id)
        XCTAssertEqual(shown?.scene, "bookmarks")
    }

    func testCopiesPlacedAboveBottomBarsKeepTheToastsID() {
        let toast = Toast("Removed")
        var queue = ToastQueue<String>()
        queue.append(toast.clearingBottomBars(height: 83, spacing: 8), in: "bookmarks")
        _ = queue.showNext()

        XCTAssertTrue(queue.removeToast(id: toast.id))
    }
}
