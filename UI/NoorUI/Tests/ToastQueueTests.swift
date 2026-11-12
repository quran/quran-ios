import XCTest
@testable import NoorUI

final class ToastQueueTests: XCTestCase {
    func testRemovingAnotherToastLeavesTheShowingToastShowing() {
        let otherFeatureToast = Toast("Collection created")
        let bannerToast = Toast("Playing")
        var queue = ToastQueue<String>()
        queue.append(otherFeatureToast, to: "reader")
        _ = queue.showNext()

        queue.removeWaiting(id: bannerToast.id)

        XCTAssertEqual(queue.showing?.toast.id, otherFeatureToast.id)
    }

    func testRemovingAWaitingToastDropsIt() {
        let showing = Toast("Collection created")
        let downloading = Toast("Downloading")
        let playing = Toast("Playing")
        var queue = ToastQueue<String>()
        queue.append(showing, to: "reader")
        queue.append(downloading, to: "reader")
        queue.append(playing, to: "reader")
        _ = queue.showNext()

        queue.removeWaiting(id: downloading.id)
        queue.removeShowing()

        XCTAssertEqual(queue.showNext()?.toast.id, playing.id)
    }

    func testTheShowingToastStaysUntilRemovedThenTheNextShows() {
        let playing = Toast("Playing")
        let next = Toast("Collection created")
        var queue = ToastQueue<String>()
        queue.append(playing, to: "reader")
        queue.append(next, to: "bookmarks")
        _ = queue.showNext()

        queue.removeWaiting(id: playing.id)

        XCTAssertEqual(queue.showing?.toast.id, playing.id)
        XCTAssertNil(queue.showNext(), "The showing toast stays until it animates away.")
        queue.removeShowing()
        let shown = queue.showNext()
        XCTAssertEqual(shown?.toast.id, next.id)
        XCTAssertEqual(shown?.target, "bookmarks")
    }
}
