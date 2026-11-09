import XCTest
@testable import NoorUI

final class ToastQueueTests: XCTestCase {
    func testRemovingAnotherToastLeavesTheShowingToastShowing() {
        let otherFeatureToast = Toast("Collection created")
        let bannerToast = Toast("Playing")
        var queue = ToastQueue<String>()
        queue.append(otherFeatureToast, in: "reader")
        _ = queue.showNext()

        queue.removeWaiting(id: bannerToast.id)

        XCTAssertEqual(queue.showing?.toast.id, otherFeatureToast.id)
    }

    func testRemovingAWaitingToastDropsIt() {
        let showing = Toast("Collection created")
        let downloading = Toast("Downloading")
        let playing = Toast("Playing")
        var queue = ToastQueue<String>()
        queue.append(showing, in: "reader")
        queue.append(downloading, in: "reader")
        queue.append(playing, in: "reader")
        _ = queue.showNext()

        queue.removeWaiting(id: downloading.id)
        queue.removeShowing()

        XCTAssertEqual(queue.showNext()?.toast.id, playing.id)
    }

    func testTheShowingToastStaysUntilRemovedThenTheNextShows() {
        let playing = Toast("Playing")
        let next = Toast("Collection created")
        var queue = ToastQueue<String>()
        queue.append(playing, in: "reader")
        queue.append(next, in: "bookmarks")
        _ = queue.showNext()

        queue.removeWaiting(id: playing.id)

        XCTAssertEqual(queue.showing?.toast.id, playing.id)
        XCTAssertNil(queue.showNext(), "The showing toast stays until it animates away.")
        queue.removeShowing()
        let shown = queue.showNext()
        XCTAssertEqual(shown?.toast.id, next.id)
        XCTAssertEqual(shown?.scene, "bookmarks")
    }
}
