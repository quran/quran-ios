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
