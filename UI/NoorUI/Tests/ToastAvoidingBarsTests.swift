import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class ToastAvoidingBarsTests: XCTestCase {
    func testBarReportsItsFrameInTheWindow() {
        let context = makeBar()

        XCTAssertEqual(bars(in: context.window).map(\.frame), [CGRect(x: 0, y: 710, width: 402, height: 164)])
        XCTAssertEqual(bars(in: context.window).map(\.isVisible), [true])
    }

    func testBarFollowsItsContainerIntoTheWindowCoordinates() {
        let context = makeBar()
        context.container.frame.origin.y = 100

        XCTAssertEqual(bars(in: context.window).map(\.frame.minY), [810])
    }

    func testHiddenBarDoesNotShow() {
        let context = makeBar()
        context.bar.isHidden = true

        XCTAssertEqual(bars(in: context.window).map(\.isVisible), [false])
    }

    func testBarInAHiddenContainerDoesNotShow() {
        let context = makeBar()
        context.container.isHidden = true

        XCTAssertEqual(bars(in: context.window).map(\.isVisible), [false])
    }

    func testFadedOutBarDoesNotShow() {
        let context = makeBar()
        context.bar.alpha = 0

        XCTAssertEqual(bars(in: context.window).map(\.isVisible), [false])
    }

    func testBarOutsideAWindowIsIgnored() {
        let context = makeBar()
        context.container.removeFromSuperview()

        XCTAssertTrue(bars(in: context.window).isEmpty)
    }

    func testBarThatStopsKeepingToastsAboveIsIgnored() {
        let context = makeBar()
        context.bar.keepsToastsAbove = false

        XCTAssertFalse(context.bar.keepsToastsAbove)
        XCTAssertTrue(bars(in: context.window).isEmpty)
    }

    func testKeepingToastsAboveTwiceDeclaresTheBarOnce() {
        let context = makeBar()
        context.bar.keepsToastsAbove = true

        XCTAssertTrue(context.bar.keepsToastsAbove)
        XCTAssertEqual(bars(in: context.window).count, 1)
    }

    func testBarWithoutPresentedScreensHasNoScreensAbove() {
        let context = makeBar()

        XCTAssertEqual(bars(in: context.window).map(\.screensAbove), [[]])
    }

    // MARK: Private

    private struct Context {
        let window: UIWindow
        let container: UIView
        let bar: UIView
    }

    /// The reader's audio bar at the bottom of an iPhone 17 Pro window.
    private func makeBar() -> Context {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.isHidden = false
        let container = UIView(frame: window.bounds)
        window.addSubview(container)
        let bar = UIView(frame: CGRect(x: 0, y: 710, width: 402, height: 164))
        bar.keepsToastsAbove = true
        container.addSubview(bar)
        return Context(window: window, container: container, bar: bar)
    }

    private func bars(in window: UIWindow) -> [ToastPlacement.Bar] {
        ToastAvoidingBars.placementBars(in: window)
    }
}
