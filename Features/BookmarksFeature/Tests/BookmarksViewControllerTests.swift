#if !QURAN_SYNC
import UIKit
import XCTest
@testable import BookmarksFeature

@MainActor
final class BookmarksViewControllerTests: XCTestCase {
    func testDeleteAllConfirmationAnchorsActionSheetToSourceButton() throws {
        let source = UIBarButtonItem(systemItem: .trash)

        let alert = BookmarksViewController.makeDeleteAllConfirmation(
            sourceBarButtonItem: source,
            deleteAll: {}
        )

        XCTAssertTrue(try XCTUnwrap(alert.popoverPresentationController?.barButtonItem) === source)
    }
}
#endif
