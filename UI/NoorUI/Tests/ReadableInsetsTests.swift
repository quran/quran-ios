import SwiftUI
import XCTest
@testable import NoorUI

final class ReadableInsetsTests: XCTestCase {
    // A window whose physical left inset is 12 and right inset is 40, with leading and trailing
    // in each layout direction.
    private let leftToRightInsets = EdgeInsets(top: 24, leading: 12, bottom: 20, trailing: 40)
    private let rightToLeftInsets = EdgeInsets(top: 24, leading: 40, bottom: 20, trailing: 12)

    func test_innerLeft_leftToRight_dropsTheLeftInset() {
        let insets = pageSafeAreaInsets(leftToRightInsets, pageInnerSide: .left, layoutDirection: .leftToRight)

        XCTAssertEqual(insets, EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 40))
    }

    func test_innerLeft_rightToLeft_dropsTheLeftInset() {
        let insets = pageSafeAreaInsets(rightToLeftInsets, pageInnerSide: .left, layoutDirection: .rightToLeft)

        XCTAssertEqual(insets, EdgeInsets(top: 24, leading: 40, bottom: 20, trailing: 0))
    }

    func test_innerRight_leftToRight_dropsTheRightInset() {
        let insets = pageSafeAreaInsets(leftToRightInsets, pageInnerSide: .right, layoutDirection: .leftToRight)

        XCTAssertEqual(insets, EdgeInsets(top: 24, leading: 12, bottom: 20, trailing: 0))
    }

    func test_innerRight_rightToLeft_dropsTheRightInset() {
        let insets = pageSafeAreaInsets(rightToLeftInsets, pageInnerSide: .right, layoutDirection: .rightToLeft)

        XCTAssertEqual(insets, EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 12))
    }

    func test_symmetricSideInsets_dropsTheInnerSideInset() {
        // Like a big iPhone in landscape, with the Dynamic Island's inset mirrored on the other edge.
        let windowInsets = EdgeInsets(top: 0, leading: 59, bottom: 21, trailing: 59)

        let insets = pageSafeAreaInsets(windowInsets, pageInnerSide: .right, layoutDirection: .leftToRight)

        XCTAssertEqual(insets, EdgeInsets(top: 0, leading: 59, bottom: 21, trailing: 0))
    }

    func test_withoutInnerSide_keepsTheWindowInsets() {
        let insets = pageSafeAreaInsets(rightToLeftInsets, pageInnerSide: nil, layoutDirection: .rightToLeft)

        XCTAssertEqual(insets, rightToLeftInsets)
    }

    // MARK: Private

    private func pageSafeAreaInsets(
        _ windowSafeAreaInsets: EdgeInsets,
        pageInnerSide: PageInnerSide?,
        layoutDirection: LayoutDirection
    ) -> EdgeInsets {
        ReadableInsetsModifier.pageSafeAreaInsets(
            windowSafeAreaInsets: windowSafeAreaInsets,
            pageInnerSide: pageInnerSide,
            layoutDirection: layoutDirection
        )
    }
}
