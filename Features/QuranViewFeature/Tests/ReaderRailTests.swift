//
//  ReaderRailTests.swift
//

import UIKit
import XCTest
@testable import QuranViewFeature

@MainActor
final class ReaderRailTests: XCTestCase {
    // MARK: Internal

    func test_systemBars_showOnlyWithAVerticalBarAndTheReadersBars() {
        let shown = ReaderRail.hiddenBars(hasVerticalBar: true, barsHidden: false, hasAudioItems: true)
        XCTAssertFalse(shown.navigationBar)
        XCTAssertFalse(shown.toolbar)

        XCTAssertTrue(ReaderRail.hiddenBars(hasVerticalBar: false, barsHidden: false, hasAudioItems: true).navigationBar)
        XCTAssertTrue(ReaderRail.hiddenBars(hasVerticalBar: true, barsHidden: true, hasAudioItems: true).navigationBar)
        XCTAssertTrue(ReaderRail.hiddenBars(hasVerticalBar: true, barsHidden: false, hasAudioItems: false).toolbar)
    }

    func test_popover_pointsAtTheItemsPageSide() {
        let anchor = ReaderRail.popoverAnchor(
            itemFrame: CGRect(x: 8, y: 120, width: 44, height: 44),
            in: bounds,
            safeAreaInsets: safeAreaInsets,
            side: .left
        )

        XCTAssertEqual(anchor.rect, CGRect(x: 52, y: 120, width: 1, height: 44))
        XCTAssertEqual(anchor.arrowDirection, .left)
    }

    func test_popoverFromAnItemNotLaidOut_pointsAtTheRailsEdge() {
        let anchor = ReaderRail.popoverAnchor(itemFrame: nil, in: bounds, safeAreaInsets: safeAreaInsets, side: .right)

        XCTAssertEqual(anchor.rect, CGRect(x: 867, y: 20, width: 1, height: 629))
        XCTAssertEqual(anchor.arrowDirection, .right)
    }

    // MARK: Private

    private let bounds = CGRect(x: 0, y: 0, width: 951, height: 669)
    private let safeAreaInsets = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 84)
}
