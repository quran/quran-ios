import SwiftUI
import UIKit
import XCTest
@testable import UIx

final class EdgeInsetsLayoutDirectionTests: XCTestCase {
    func test_init_leftToRight_placesLeftAsLeading() {
        let insets = EdgeInsets(top: 24, left: 12, bottom: 20, right: 40, layoutDirection: .leftToRight)

        XCTAssertEqual(insets, EdgeInsets(top: 24, leading: 12, bottom: 20, trailing: 40))
    }

    func test_init_rightToLeft_placesRightAsLeading() {
        let insets = EdgeInsets(top: 24, left: 12, bottom: 20, right: 40, layoutDirection: .rightToLeft)

        XCTAssertEqual(insets, EdgeInsets(top: 24, leading: 40, bottom: 20, trailing: 12))
    }

    func test_leftAndRight_leftToRight_readLeadingAsLeft() {
        let insets = EdgeInsets(top: 24, leading: 12, bottom: 20, trailing: 40)

        XCTAssertEqual(insets.left(in: .leftToRight), 12)
        XCTAssertEqual(insets.right(in: .leftToRight), 40)
    }

    func test_leftAndRight_rightToLeft_readLeadingAsRight() {
        let insets = EdgeInsets(top: 24, leading: 40, bottom: 20, trailing: 12)

        XCTAssertEqual(insets.left(in: .rightToLeft), 12)
        XCTAssertEqual(insets.right(in: .rightToLeft), 40)
    }

    func test_leftAndRight_giveBackTheInitInputsInBothDirections() {
        for layoutDirection in [LayoutDirection.leftToRight, .rightToLeft] {
            let insets = EdgeInsets(left: 12, right: 40, layoutDirection: layoutDirection)

            XCTAssertEqual(insets.left(in: layoutDirection), 12, "\(layoutDirection)")
            XCTAssertEqual(insets.right(in: layoutDirection), 40, "\(layoutDirection)")
        }
    }

    // MARK: Window safe area insets

    func test_windowInsets_leftToRight_keepLeftAsLeading() {
        // Like an unfolded iPhone Duo's window, with the vertical bar on the right.
        let insets = EdgeInsets(UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 40), layoutDirection: .leftToRight)

        XCTAssertEqual(insets, EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 40))
    }

    func test_windowInsets_rightToLeft_makeRightTheLeading() {
        let insets = EdgeInsets(UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 40), layoutDirection: .rightToLeft)

        XCTAssertEqual(insets, EdgeInsets(top: 24, leading: 40, bottom: 20, trailing: 0))
    }
}
