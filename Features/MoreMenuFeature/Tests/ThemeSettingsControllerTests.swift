import SwiftUI
import XCTest
@testable import MoreMenuFeature

@MainActor
final class ThemeSettingsControllerTests: XCTestCase {
    func testSheetContentScrollDoesNotDriveDetentInteraction() throws {
        let sut = ThemeSettingsController(rootView: EmptyView())
        sut.modalPresentationStyle = .formSheet

        sut.loadViewIfNeeded()

        let sheet = try XCTUnwrap(sut.sheetPresentationController)
        XCTAssertFalse(sheet.prefersScrollingExpandsWhenScrolledToEdge)
    }
}
