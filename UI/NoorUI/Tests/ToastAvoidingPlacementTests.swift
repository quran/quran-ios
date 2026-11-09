import XCTest
@testable import NoorUI

/// An iPhone 17 Pro window: 402 × 874 in portrait with a 34pt home indicator inset, 874 × 402 in landscape with 21pt.
final class ToastAvoidingPlacementTests: XCTestCase {
    func testWithoutBarsTheToastKeepsItsOffset() {
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34)

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 40)
    }

    func testToastSitsAboveABar() {
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34, bars: [audioBar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 172)
    }

    func testHighestOfSeveralBarsWins() {
        let lowBar = ToastPlacement.Bar(frame: CGRect(x: 0, y: 760, width: 402, height: 114))
        let highBar = ToastPlacement.Bar(frame: CGRect(x: 16, y: 700, width: 370, height: 60))
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34, bars: [lowBar, highBar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 182)
    }

    func testHiddenBarIsSkipped() {
        var hiddenBar = audioBar
        hiddenBar.isVisible = false
        let lowBar = ToastPlacement.Bar(frame: CGRect(x: 0, y: 760, width: 402, height: 114))
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34, bars: [hiddenBar, lowBar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 122)
    }

    func testBarUnderAFullHeightSheetIsSkipped() {
        var bar = audioBar
        bar.screensAbove = [CGRect(x: 0, y: 62, width: 402, height: 812)]
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 40)
    }

    func testBarUnderAFloatingMediumDetentSheetIsSkipped() {
        var bar = audioBar
        bar.screensAbove = [CGRect(x: 8, y: 437, width: 386, height: 429)]
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 40)
    }

    func testBarUnderAPopoverStillCounts() {
        var bar = audioBar
        bar.screensAbove = [CGRect(x: 16, y: 120, width: 370, height: 360)]
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 172)
    }

    func testBarPartlyUnderATallPopoverStillCounts() {
        var bar = audioBar
        // The popover overlaps the bar's top but stays inside the safe area.
        bar.screensAbove = [CGRect(x: 16, y: 120, width: 370, height: 700)]
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 172)
    }

    func testBarUnderAPopoverAboveASheetIsSkipped() {
        var bar = audioBar
        bar.screensAbove = [
            CGRect(x: 0, y: 62, width: 402, height: 812),
            CGRect(x: 16, y: 120, width: 370, height: 360),
        ]
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 40)
    }

    func testBarBelowAnIPadFormSheetStillCounts() {
        let bar = ToastPlacement.Bar(
            frame: CGRect(x: 0, y: 1050, width: 820, height: 130),
            screensAbove: [CGRect(x: 110, y: 170, width: 600, height: 840)]
        )
        let placement = ToastPlacement(windowSize: CGSize(width: 820, height: 1180), windowBottomInset: 20, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 138)
    }

    func testBarWiderThanAnIPadPageSheetStillCounts() {
        let bar = ToastPlacement.Bar(
            frame: CGRect(x: 0, y: 1050, width: 820, height: 130),
            screensAbove: [CGRect(x: 60, y: 40, width: 700, height: 1140)]
        )
        let placement = ToastPlacement(windowSize: CGSize(width: 820, height: 1180), windowBottomInset: 20, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 138)
    }

    func testBarOutsideTheWindowIsSkipped() {
        // A sheet's bar starts below the window while the sheet slides up.
        let bar = ToastPlacement.Bar(frame: CGRect(x: 0, y: 900, width: 402, height: 80))
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 40)
    }

    func testScreenBarsRaiseTheToastWithoutDeclaredBars() {
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34, screenBarsHeight: 83)

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 91)
    }

    func testBarLowerThanTheScreenBarsDoesNotLowerTheToast() {
        let bar = ToastPlacement.Bar(frame: CGRect(x: 0, y: 824, width: 402, height: 50))
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34, screenBarsHeight: 83, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 91)
    }

    func testBarHigherThanTheScreenBarsRaisesTheToast() {
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34, screenBarsHeight: 83, bars: [audioBar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 172)
    }

    func testToastKeepsALargerOffsetThanTheBars() {
        let placement = ToastPlacement(windowSize: portrait, windowBottomInset: 34, bars: [audioBar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 200, spacing: 8), 200)
    }

    func testLandscapeBarRaisesTheToast() {
        let bar = ToastPlacement.Bar(frame: CGRect(x: 0, y: 290, width: 874, height: 112))
        let placement = ToastPlacement(windowSize: landscape, windowBottomInset: 21, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 120)
    }

    func testLandscapeBarUnderAFullScreenSheetIsSkipped() {
        let bar = ToastPlacement.Bar(
            frame: CGRect(x: 0, y: 290, width: 874, height: 112),
            screensAbove: [CGRect(origin: .zero, size: landscape)]
        )
        let placement = ToastPlacement(windowSize: landscape, windowBottomInset: 21, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 40)
    }

    func testLandscapeBarUnderAPopoverStillCounts() {
        let bar = ToastPlacement.Bar(
            frame: CGRect(x: 0, y: 290, width: 874, height: 112),
            screensAbove: [CGRect(x: 250, y: 40, width: 374, height: 300)]
        )
        let placement = ToastPlacement(windowSize: landscape, windowBottomInset: 21, bars: [bar])

        XCTAssertEqual(placement.bottomOffset(toastOffset: 40, spacing: 8), 120)
    }

    // MARK: Private

    private let portrait = CGSize(width: 402, height: 874)
    private let landscape = CGSize(width: 874, height: 402)
    /// The reader's audio bar, home indicator area included.
    private let audioBar = ToastPlacement.Bar(frame: CGRect(x: 0, y: 710, width: 402, height: 164))
}
