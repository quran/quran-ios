import SwiftUI
import UIKit
import XCTest
@testable import UIx

@MainActor
final class MinimumTouchTargetTests: XCTestCase {
    func testSmallLabelGetsMinimumSize() {
        let size = fittingSize(
            Color.clear.frame(width: 12, height: 12).minimumTouchTarget()
                .dynamicTypeSize(.large)
        )
        XCTAssertEqual(size.width, 44, accuracy: 0.5)
        XCTAssertEqual(size.height, 44, accuracy: 0.5)
    }

    func testLargerLabelIsNotShrunk() {
        let size = fittingSize(
            Color.clear.frame(width: 100, height: 60).minimumTouchTarget()
                .dynamicTypeSize(.large)
        )
        XCTAssertEqual(size.width, 100, accuracy: 0.5)
        XCTAssertEqual(size.height, 60, accuracy: 0.5)
    }

    func testMinimumStaysFixedAcrossDynamicTypeSizes() {
        for dynamicTypeSize in [DynamicTypeSize.xSmall, .accessibility5] {
            let size = fittingSize(
                Color.clear.frame(width: 12, height: 12).minimumTouchTarget()
                    .dynamicTypeSize(dynamicTypeSize)
            )
            XCTAssertEqual(size.width, 44, accuracy: 0.5)
            XCTAssertEqual(size.height, 44, accuracy: 0.5)
        }
    }

    func testScaledTextCanGrowBeyondTheMinimum() {
        let size = fittingSize(
            Text("Tap").font(.body).minimumTouchTarget()
                .dynamicTypeSize(.accessibility5)
        )
        XCTAssertGreaterThan(size.height, 44)
    }

    private func fittingSize(_ view: some View) -> CGSize {
        let controller = UIHostingController(rootView: view)
        return controller.sizeThatFits(in: CGSize(width: 1000, height: 1000))
    }
}
