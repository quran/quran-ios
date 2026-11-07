import Localization
import NoorUI
import QuranAnnotations
import UIKit
import XCTest
@testable import BookmarksFeature

@MainActor
final class DeleteAllConfirmationTests: XCTestCase {
    func test_make_confirmsWithTheMessageAndADestructiveDeleteAll() {
        let alert = DeleteAllConfirmation.make(
            message: "Remove everything?",
            sourceBarButtonItem: UIBarButtonItem(),
            deleteAll: {}
        )

        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.title, l("bookmarks.delete-all"))
        XCTAssertEqual(alert.message, "Remove everything?")
        XCTAssertEqual(alert.actions.map(\.title), [l("bookmarks.delete-all"), lAndroid("cancel")])
        XCTAssertEqual(alert.actions.map(\.style), [.destructive, .cancel])
    }

    func test_message_namesTheCollectionOrTheColor() {
        XCTAssertEqual(
            DeleteAllConfirmation.message(collectionName: "Duas"),
            lFormat("bookmarks.collections.ayahs.delete-all.confirmation", "Duas")
        )
        XCTAssertEqual(
            DeleteAllConfirmation.message(highlightColor: .green),
            lFormat("bookmarks.collections.ayahs.delete-all.colored.confirmation", HighlightColor.green.localizedName)
        )
    }

    func test_make_anchorsActionSheetToSourceButton() throws {
        let source = UIBarButtonItem(systemItem: .trash)

        let alert = DeleteAllConfirmation.make(
            message: "",
            sourceBarButtonItem: source,
            deleteAll: {}
        )

        XCTAssertTrue(try XCTUnwrap(alert.popoverPresentationController?.barButtonItem) === source)
    }
}
