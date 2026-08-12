import SwiftUI
import XCTest
@testable import NoorUI

@MainActor
final class BuilderClosureLifetimeTests: XCTestCase {
    func testSegmentedChoicesPickerDoesNotStoreLabelBuilder() {
        assertBuilderReleased { token in
            SegmentedChoicesPicker(
                title: "Title",
                items: [1],
                selection: .constant(1),
                label: { _ in token.text }
            )
        }
    }

    func testDropdownButtonDoesNotStoreContentBuilder() {
        assertBuilderReleased { token in
            DropdownButton(items: [1], selectedItem: .constant(1)) { _ in
                Text(token.text)
            }
        }
    }

    func testNoorSectionDoesNotStoreListItemBuilder() {
        assertBuilderReleased { token in
            NoorSection([Item(id: 1)]) { _ in
                Text(token.text)
            }
        }
    }

    func testNoorEditableCollapsibleSectionDoesNotStoreListItemBuilder() {
        assertBuilderReleased { token in
            NoorEditableCollapsibleSection(
                title: "Title",
                isExpanded: .constant(true),
                [Item(id: 1)]
            ) { _ in
                Text(token.text)
            }
        }
    }

    private func assertBuilderReleased(
        _ makeView: (Token) -> Any,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        weak var weakToken: Token?
        var retainedView: Any?

        autoreleasepool {
            let token = Token()
            weakToken = token
            retainedView = makeView(token)
        }

        XCTAssertNil(weakToken, file: file, line: line)
        withExtendedLifetime(retainedView) { }
    }
}

private final class Token {
    let text = "Text"
}

private struct Item: Identifiable {
    let id: Int
}
