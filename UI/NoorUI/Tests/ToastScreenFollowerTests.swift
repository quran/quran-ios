import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class ToastScreenFollowerTests: XCTestCase {
    func testFollowingAScreenObservesItsView() {
        let context = makeScreen()
        let follower = ToastScreenFollower()

        follower.followViews(of: [context.screen])

        XCTAssertEqual(context.screen.view.subviews.count, context.subviewsBefore + 1)
        XCTAssertTrue(context.screen.view.subviews.last?.isHidden ?? false, "The observer never shows.")
        XCTAssertFalse(context.screen.view.subviews.last?.isUserInteractionEnabled ?? true)
    }

    func testFollowingAScreenTwiceObservesItOnce() {
        let context = makeScreen()
        let follower = ToastScreenFollower()

        follower.followViews(of: [context.screen])
        follower.followViews(of: [context.screen])

        XCTAssertEqual(context.screen.view.subviews.count, context.subviewsBefore + 1)
    }

    func testScreenOutsideAWindowIsNotObserved() {
        let screen = UIViewController()
        let subviewsBefore = screen.view.subviews.count
        let follower = ToastScreenFollower()

        follower.followViews(of: [screen])

        XCTAssertEqual(screen.view.subviews.count, subviewsBefore)
    }

    func testStoppingRemovesTheObservers() {
        let context = makeScreen()
        let follower = ToastScreenFollower()
        follower.followViews(of: [context.screen])

        follower.stop()

        XCTAssertEqual(context.screen.view.subviews.count, context.subviewsBefore)
    }

    func testObservingAScreenDoesNotMakeItABar() {
        let context = makeScreen()
        let follower = ToastScreenFollower()

        follower.followViews(of: [context.screen])

        XCTAssertFalse(context.screen.view.keepsToastsAbove)
        XCTAssertTrue(ToastAvoidingBars.snapshot(in: context.window).bars.isEmpty)
    }

    // MARK: Private

    private struct Context {
        let window: UIWindow
        let screen: UIViewController
        let subviewsBefore: Int
    }

    private func makeScreen() -> Context {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.isHidden = false
        let screen = UIViewController()
        window.rootViewController = screen
        return Context(window: window, screen: screen, subviewsBefore: screen.view.subviews.count)
    }
}
