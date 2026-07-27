import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class NavigationActionsTests: XCTestCase {
    func test_editButton_usesSystemPresentation() {
        assertSystemPresentation(
            NavigationBarButton.edit { },
            systemItem: .edit,
            tintColor: nil
        )
    }

    func test_doneButton_usesSystemPresentation() {
        assertSystemPresentation(
            NavigationBarButton.done { },
            systemItem: .done,
            tintColor: .appIdentity
        )
    }

    func test_closeButton_usesSystemPresentation() {
        assertSystemPresentation(
            NavigationBarButton.close { },
            systemItem: .close,
            tintColor: nil
        )
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
