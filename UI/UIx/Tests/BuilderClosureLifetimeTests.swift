import SwiftUI
import UIKit
import XCTest
@testable import UIx

@MainActor
final class BuilderClosureLifetimeTests: XCTestCase {
    func testSingleChoiceSelectorViewDoesNotStoreTextBuilder() {
        assertBuilderReleased { token in
            SingleChoiceSelectorView(
                sections: [SingleChoiceSection(items: [1])],
                selected: .constant(1),
                itemText: { _ in token.text }
            )
        }
    }

    func testSingleChoiceSelectorDoesNotStoreConfigurationBuilder() {
        assertBuilderReleased { token in
            SingleChoiceSelector(
                style: .insetGrouped,
                sections: [SingleChoiceSection(items: [1])],
                selected: 1,
                configure: { _, _ in Text(token.text) },
                onSelection: { _ in }
            )
        }
    }

    func testCollectionViewDoesNotStoreContentBuilder() {
        assertBuilderReleased { token in
            CollectionView(
                layout: UICollectionViewFlowLayout(),
                sections: [ListSection(sectionId: 0, items: [Item(id: 1)])]
            ) { _, _ in
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

private struct Item: Identifiable, Hashable {
    let id: Int
}
