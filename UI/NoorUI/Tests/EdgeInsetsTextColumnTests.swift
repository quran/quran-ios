import SwiftUI
import XCTest
@testable import NoorUI

final class EdgeInsetsTextColumnTests: XCTestCase {
    func testInsetsReachTheTextInACentredImage() {
        // The image view is 500 wide in content 600 wide, leaving 50 points either side.
        let insets = insets(contentWidth: 600, layoutDirection: .leftToRight)

        XCTAssertEqual(insets, EdgeInsets(top: 0, leading: 100, bottom: 0, trailing: 75))
    }

    func testRightToLeftSwapsLeadingAndTrailing() {
        let insets = insets(contentWidth: 600, layoutDirection: .rightToLeft)

        XCTAssertEqual(insets, EdgeInsets(top: 0, leading: 75, bottom: 0, trailing: 100))
    }

    func testMissingColumnOrUnmeasuredContentHasNoInsets() {
        XCTAssertNil(insets(textColumn: nil, contentWidth: 600, layoutDirection: .leftToRight))
        XCTAssertNil(insets(contentWidth: 0, layoutDirection: .leftToRight))
    }

    func testLandscapeRoundingDoesNotPullTheInsetsOutward() {
        let insets = insets(contentWidth: imageViewSize.width - 0.001, layoutDirection: .leftToRight)

        XCTAssertEqual(insets, EdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 25))
    }

    func testTrimmedMarginsMeasureTheTextInTheVisiblePart() {
        // Only x 50 to 950 of the image fills an image view 450 wide, scaled by 0.5, so the text is 25 to 450 points.
        let insets = EdgeInsets(
            textColumn: 100 ... 950,
            imageSize: imageSize,
            visibleRect: CGRect(x: 50, y: 0, width: 900, height: 2000),
            imageViewSize: CGSize(width: 450, height: 1000),
            contentWidth: 600,
            layoutDirection: .leftToRight
        )

        XCTAssertEqual(insets, EdgeInsets(top: 0, leading: 100, bottom: 0, trailing: 75))
    }

    // MARK: Private

    private let imageSize = CGSize(width: 1000, height: 2000)
    private let imageViewSize = CGSize(width: 500, height: 1000)

    /// Text from x 100 to 950 in the image is 50 to 475 points in the image view.
    private func insets(
        textColumn: ClosedRange<CGFloat>? = 100 ... 950,
        contentWidth: CGFloat,
        layoutDirection: LayoutDirection
    ) -> EdgeInsets? {
        EdgeInsets(
            textColumn: textColumn,
            imageSize: imageSize,
            imageViewSize: imageViewSize,
            contentWidth: contentWidth,
            layoutDirection: layoutDirection
        )
    }
}
