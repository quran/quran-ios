import XCTest
@testable import NoorUI

final class ReadingBookmarkIconTests: XCTestCase {
    func test_badgedImages_areTemplateRenderedAtNavigationBarSize() throws {
        let outline = ReadingBookmarkIcon.image(style: .outline, badge: .ellipsis)
        let filled = ReadingBookmarkIcon.image(style: .filled, badge: .ellipsis)

        XCTAssertEqual(outline.size, CGSize(width: 24, height: 24))
        XCTAssertEqual(filled.size, CGSize(width: 24, height: 24))
        XCTAssertEqual(outline.renderingMode, .alwaysTemplate)
        XCTAssertEqual(filled.renderingMode, .alwaysTemplate)
        XCTAssertNotEqual(try XCTUnwrap(outline.pngData()), try XCTUnwrap(filled.pngData()))
    }
}
