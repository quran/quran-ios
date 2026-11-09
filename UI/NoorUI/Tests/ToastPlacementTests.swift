import UIKit
import XCTest
@testable import NoorUI

/// An iPhone 17 Pro window: 402 × 874 in portrait, 874 × 402 in landscape.
final class ToastPlacementTests: XCTestCase {
    // MARK: Screen bars

    func testTabBarAboveHomeIndicatorCountsAsBottomBars() {
        let height = ToastPlacement.screenBarsHeight(windowHeight: 874, windowBottomInset: 34, screenBottom: 874, screenBottomInset: 83)
        XCTAssertEqual(height, 83)
    }

    func testHomeIndicatorAloneIsNotBottomBars() {
        let height = ToastPlacement.screenBarsHeight(windowHeight: 874, windowBottomInset: 34, screenBottom: 874, screenBottomInset: 34)
        XCTAssertEqual(height, 0)
    }

    func testScreenEndingAboveWindowBottomWithoutInsetHasNoBottomBars() {
        // A popover ends mid-window and has nothing below its content.
        let height = ToastPlacement.screenBarsHeight(windowHeight: 874, windowBottomInset: 34, screenBottom: 420, screenBottomInset: 0)
        XCTAssertEqual(height, 0)
    }

    func testPopoverWithDownArrowHasNoBottomBars() {
        // A down arrow gives the popover a bottom inset even though it ends mid-window.
        let height = ToastPlacement.screenBarsHeight(windowHeight: 874, windowBottomInset: 34, screenBottom: 500, screenBottomInset: 13)
        XCTAssertEqual(height, 0)
    }

    func testLandscapeTabBarCountsAsBottomBars() {
        let height = ToastPlacement.screenBarsHeight(windowHeight: 402, windowBottomInset: 21, screenBottom: 402, screenBottomInset: 53)
        XCTAssertEqual(height, 53)
    }

    func testIPadTopTabBarLeavesNoBottomBars() {
        let height = ToastPlacement.screenBarsHeight(windowHeight: 1194, windowBottomInset: 20, screenBottom: 1194, screenBottomInset: 20)
        XCTAssertEqual(height, 0)
    }

    // MARK: Bars that keep toasts above them

    func testWithoutBarsTheToastKeepsItsOffset() {
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets)

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 40)
    }

    func testToastSitsAboveABar() {
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets, bars: [audioBar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 172)
    }

    func testHighestOfSeveralBarsWins() {
        let lowBar = ToastPlacement.Bar(frame: CGRect(x: 0, y: 760, width: 402, height: 114))
        let highBar = ToastPlacement.Bar(frame: CGRect(x: 16, y: 700, width: 370, height: 60))
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets, bars: [lowBar, highBar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 182)
    }

    func testHiddenBarIsSkipped() {
        var hiddenBar = audioBar
        hiddenBar.isVisible = false
        let lowBar = ToastPlacement.Bar(frame: CGRect(x: 0, y: 760, width: 402, height: 114))
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets, bars: [hiddenBar, lowBar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 122)
    }

    func testBarUnderAFullHeightSheetIsSkipped() {
        var bar = audioBar
        bar.screensAbove = [CGRect(x: 0, y: 62, width: 402, height: 812)]
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 40)
    }

    func testBarUnderAFloatingMediumDetentSheetIsSkipped() {
        var bar = audioBar
        bar.screensAbove = [CGRect(x: 8, y: 437, width: 386, height: 429)]
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 40)
    }

    func testBarUnderAPopoverStillCounts() {
        var bar = audioBar
        bar.screensAbove = [CGRect(x: 16, y: 120, width: 370, height: 360)]
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 172)
    }

    func testBarPartlyUnderATallPopoverStillCounts() {
        var bar = audioBar
        // The popover overlaps the bar's top but stays inside the safe area.
        bar.screensAbove = [CGRect(x: 16, y: 120, width: 370, height: 700)]
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 172)
    }

    func testBarUnderAPopoverAboveASheetIsSkipped() {
        var bar = audioBar
        bar.screensAbove = [
            CGRect(x: 0, y: 62, width: 402, height: 812),
            CGRect(x: 16, y: 120, width: 370, height: 360),
        ]
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 40)
    }

    func testBarBelowAnIPadFormSheetStillCounts() {
        let bar = ToastPlacement.Bar(
            frame: CGRect(x: 0, y: 1050, width: 820, height: 130),
            screensAbove: [CGRect(x: 110, y: 170, width: 600, height: 840)]
        )
        let placement = ToastPlacement(windowSize: CGSize(width: 820, height: 1180), windowSafeAreaInsets: iPadInsets, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 138)
    }

    func testBarWiderThanAnIPadPageSheetStillCounts() {
        let bar = ToastPlacement.Bar(
            frame: CGRect(x: 0, y: 1050, width: 820, height: 130),
            screensAbove: [CGRect(x: 60, y: 40, width: 700, height: 1140)]
        )
        let placement = ToastPlacement(windowSize: CGSize(width: 820, height: 1180), windowSafeAreaInsets: iPadInsets, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 138)
    }

    func testBarOutsideTheWindowIsSkipped() {
        // A sheet's bar starts below the window while the sheet slides up.
        let bar = ToastPlacement.Bar(frame: CGRect(x: 0, y: 900, width: 402, height: 80))
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 40)
    }

    func testScreenBarsRaiseTheToastWithoutDeclaredBars() {
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets, screenBarsHeight: 83)

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 91)
    }

    func testBarLowerThanTheScreenBarsDoesNotLowerTheToast() {
        let bar = ToastPlacement.Bar(frame: CGRect(x: 0, y: 824, width: 402, height: 50))
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets, screenBarsHeight: 83, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 91)
    }

    func testBarHigherThanTheScreenBarsRaisesTheToast() {
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets, screenBarsHeight: 83, bars: [audioBar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 172)
    }

    func testToastKeepsALargerOffsetThanTheBars() {
        let placement = ToastPlacement(windowSize: portrait, windowSafeAreaInsets: portraitInsets, bars: [audioBar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 200, spacing: 8), 200)
    }

    func testLandscapeBarRaisesTheToast() {
        let bar = ToastPlacement.Bar(frame: CGRect(x: 0, y: 290, width: 874, height: 112))
        let placement = ToastPlacement(windowSize: landscape, windowSafeAreaInsets: landscapeInsets, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 120)
    }

    func testLandscapeBarUnderAFullScreenSheetIsSkipped() {
        let bar = ToastPlacement.Bar(
            frame: CGRect(x: 0, y: 290, width: 874, height: 112),
            screensAbove: [CGRect(origin: .zero, size: landscape)]
        )
        let placement = ToastPlacement(windowSize: landscape, windowSafeAreaInsets: landscapeInsets, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 40)
    }

    func testLandscapeBarUnderAPopoverStillCounts() {
        let bar = ToastPlacement.Bar(
            frame: CGRect(x: 0, y: 290, width: 874, height: 112),
            screensAbove: [CGRect(x: 250, y: 40, width: 374, height: 300)]
        )
        let placement = ToastPlacement(windowSize: landscape, windowSafeAreaInsets: landscapeInsets, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 120)
    }

    func testLandscapeBarUnderAPageSheetInsideTheSafeAreaIsSkipped() {
        // In landscape a page sheet stays between the sensor housing's and the home indicator's side insets.
        let bar = ToastPlacement.Bar(
            frame: CGRect(x: 0, y: 290, width: 874, height: 112),
            screensAbove: [CGRect(x: 62, y: 10, width: 750, height: 392)]
        )
        let placement = ToastPlacement(windowSize: landscape, windowSafeAreaInsets: landscapeInsets, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 40)
    }

    // MARK: Private

    private let portrait = CGSize(width: 402, height: 874)
    private let portraitInsets = UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0)
    private let landscape = CGSize(width: 874, height: 402)
    private let landscapeInsets = UIEdgeInsets(top: 0, left: 62, bottom: 21, right: 62)
    private let iPadInsets = UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0)
    /// The reader's audio bar, home indicator area included.
    private let audioBar = ToastPlacement.Bar(frame: CGRect(x: 0, y: 710, width: 402, height: 164))
}
