import SwiftUI
import UIKit
import XCTest
@testable import UIx

final class WindowSafeAreaInsetsTests: XCTestCase {
    // Like an unfolded iPhone Duo's window, with the vertical bar on the right.
    private let insets = UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 40)

    func testLeftToRightKeepsLeftAsLeading() {
        let edgeInsets = EdgeInsets(insets, layoutDirection: .leftToRight)

        XCTAssertEqual(edgeInsets, EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 40))
    }

    func testRightToLeftMakesRightTheLeading() {
        let edgeInsets = EdgeInsets(insets, layoutDirection: .rightToLeft)

        XCTAssertEqual(edgeInsets, EdgeInsets(top: 24, leading: 40, bottom: 20, trailing: 0))
    }
}
