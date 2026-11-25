#if QURAN_SYNC
import UIKit
import XCTest
@testable import NotesFeature

@MainActor
final class AyahNotesNavigationControllerTests: XCTestCase {
    func test_sheet_optsOutOfTheVerticalBarWhateverItShows() throws {
        guard #available(iOS 27.1, *) else {
            throw XCTSkip("The vertical bar behavior needs iOS 27.1.")
        }
        let navigationController = AyahNotesNavigationController(rootViewController: UIViewController())

        XCTAssertEqual(navigationController.preferredVerticalBarBehavior, .disabled)
        XCTAssertNil(navigationController.childForPreferredVerticalBarBehavior)
    }
}
#endif
