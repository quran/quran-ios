import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class NavigationActionsTests: XCTestCase {
    func test_editButton_usesSystemPresentation() {
        assertSystemPresentation(
            NavigationBarButton.edit { },
            systemItem: .edit,
            tintColor: .label
        )
    }

    func test_doneButton_usesSystemPresentation() {
        // Inherits the window tint, which follows the app icon accent.
        assertSystemPresentation(
            NavigationBarButton.done { },
            systemItem: .done,
            tintColor: nil
        )
    }

    func test_closeButton_usesSystemPresentation() {
        assertSystemPresentation(
            NavigationBarButton.close { },
            systemItem: .close,
            tintColor: .label
        )
    }

    func test_addButton_inheritsWindowTint() {
        let button = NavigationBarButton.add { }

        XCTAssertNil(button.tintColor)
        XCTAssertNotNil(button.primaryAction)
    }

    func test_overflowButton_dropsTheCircleOnLiquidGlass() {
        let expectedSymbol = if #available(iOS 26, *) {
            "ellipsis"
        } else {
            "ellipsis.circle"
        }

        XCTAssertEqual(NavigationBarButton.overflow { }.image, UIImage(systemName: expectedSymbol))
        XCTAssertEqual(NavigationBarButton.overflow(menu: UIMenu(children: [])).image, UIImage(systemName: expectedSymbol))
    }

    func test_secondaryButton_appliesGlassSymbolScaleOnLiquidGlass() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0)))

        let button = NavigationBarButton.secondary(systemName: "books.vertical", glassSymbolScale: .medium) { }

        let mediumSymbol = UIImage(systemName: "books.vertical")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(scale: .medium))
        XCTAssertEqual(button.image, mediumSymbol)
        XCTAssertNotEqual(button.image, UIImage(systemName: "books.vertical"))
        XCTAssertEqual(button.tintColor, .label)
    }

    func test_secondaryButton_keepsTheDefaultScaleWithoutGlassSymbolScale() {
        let button = NavigationBarButton.secondary(systemName: "books.vertical") { }

        XCTAssertEqual(button.image, UIImage(systemName: "books.vertical"))
    }

    private func assertSystemPresentation(
        _ button: UIBarButtonItem,
        systemItem: UIBarButtonItem.SystemItem,
        tintColor: UIColor?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expected = UIBarButtonItem(barButtonSystemItem: systemItem, target: nil, action: nil)

        XCTAssertEqual(button.title, expected.title, file: file, line: line)
        XCTAssertEqual(button.tintColor, tintColor, file: file, line: line)
        XCTAssertNotNil(button.primaryAction, file: file, line: line)
    }
}
