import SwiftUI
import XCTest
@testable import NoorUI

final class ToastPlacementTests: XCTestCase {
    func testTabBarAboveHomeIndicatorCountsAsBottomBars() {
        let height = Toast.bottomBarsHeight(windowHeight: 874, windowBottomInset: 34, screenBottom: 874, screenBottomInset: 83)
        XCTAssertEqual(height, 83)
    }

    func testHomeIndicatorAloneIsNotBottomBars() {
        let height = Toast.bottomBarsHeight(windowHeight: 874, windowBottomInset: 34, screenBottom: 874, screenBottomInset: 34)
        XCTAssertEqual(height, 0)
    }

    func testScreenEndingAboveWindowBottomWithoutInsetHasNoBottomBars() {
        // A popover ends mid-window and has nothing below its content.
        let height = Toast.bottomBarsHeight(windowHeight: 874, windowBottomInset: 34, screenBottom: 420, screenBottomInset: 0)
        XCTAssertEqual(height, 0)
    }

    func testPopoverWithDownArrowHasNoBottomBars() {
        // A down arrow gives the popover a bottom inset even though it ends mid-window.
        let height = Toast.bottomBarsHeight(windowHeight: 874, windowBottomInset: 34, screenBottom: 500, screenBottomInset: 13)
        XCTAssertEqual(height, 0)
    }

    func testLandscapeTabBarCountsAsBottomBars() {
        let height = Toast.bottomBarsHeight(windowHeight: 402, windowBottomInset: 21, screenBottom: 402, screenBottomInset: 53)
        XCTAssertEqual(height, 53)
    }

    func testIPadTopTabBarLeavesNoBottomBars() {
        let height = Toast.bottomBarsHeight(windowHeight: 1194, windowBottomInset: 20, screenBottom: 1194, screenBottomInset: 20)
        XCTAssertEqual(height, 0)
    }

    func testToastMovesAboveBottomBarsThatWouldCoverIt() {
        let toast = Toast("Removed").clearingBottomBars(height: 83, spacing: 8)
        XCTAssertEqual(toast.bottomOffset, 91)
    }

    func testToastKeepsLargerOffsetThanBottomBars() {
        let toast = Toast("Removed", bottomOffset: 100).clearingBottomBars(height: 83, spacing: 8)
        XCTAssertEqual(toast.bottomOffset, 100)
    }

    func testToastKeepsItsContentWhenMovedAboveBottomBars() {
        let toast = Toast(
            "Removed",
            subtitle: "Page 42",
            icon: Toast.Icon(.bookmarkOutline, color: .red),
            action: ToastAction(title: "Undo", handler: {}),
            showsDismissButton: true,
            duration: 6
        )
        .clearingBottomBars(height: 83, spacing: 8)

        XCTAssertEqual(toast.message.accessibilityText, "Removed")
        XCTAssertEqual(toast.subtitle?.accessibilityText, "Page 42")
        XCTAssertEqual(toast.icon?.image, NoorSystemImage.bookmarkOutline.image)
        XCTAssertEqual(toast.icon?.color, .red)
        XCTAssertEqual(toast.action?.title, "Undo")
        XCTAssertTrue(toast.showsDismissButton)
        XCTAssertEqual(toast.duration, 6)
        XCTAssertEqual(toast.bottomOffset, 91)
    }

    func testToastKeepsItsOffsetWithoutBottomBars() {
        let toast = Toast("Saved").clearingBottomBars(height: 0, spacing: 8)
        XCTAssertEqual(toast.bottomOffset, 40)
    }
}
