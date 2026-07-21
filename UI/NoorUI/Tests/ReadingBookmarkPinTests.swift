import XCTest
@testable import NoorUI

final class ReadingBookmarkPinTests: XCTestCase {
    func test_images_areTemplateRenderedAtNavigationBarSize() throws {
        let outline = ReadingBookmarkPin.image(style: .outline)
        let filled = ReadingBookmarkPin.image(style: .filled)

        XCTAssertEqual(outline.size, CGSize(width: 24, height: 24))
        XCTAssertEqual(filled.size, CGSize(width: 24, height: 24))
        XCTAssertEqual(outline.renderingMode, .alwaysTemplate)
        XCTAssertEqual(filled.renderingMode, .alwaysTemplate)
        XCTAssertNotEqual(try XCTUnwrap(outline.pngData()), try XCTUnwrap(filled.pngData()))
    }
}
