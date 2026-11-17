//
//  ImageDataServiceTextColumnTests.swift
//

import QuranKit
import TestResources
import XCTest
@testable import ImageService

final class ImageDataServiceTextColumnTests: XCTestCase {
    func testOpeningPagesHaveNoTextColumn() async throws {
        for page in Reading.hafs_1421.quran.pages.prefix(2) {
            let column = try await hafs1421.wordFrames(page, imageWidth: 1120).textColumn
            XCTAssertNil(column, "Page \(page.pageNumber)")
        }
    }

    func testAnOverhangingGlyphDoesNotSetTheEdge() async throws {
        // Page 254 of the 1405 Mushaf has a glyph well past its left margin.
        let service = ImageDataService(
            ayahInfoDatabase: TestResources.resourceURL("hafs_1405_ayahinfo.db"),
            imagesURL: TestResources.testDataURL.appendingPathComponent("images"),
            ayahMarkerURL: nil
        )
        // The fixture's images are 1280 wide; processed lines reach the outermost glyph.
        let page = Reading.hafs_1405.quran.pages[253]
        let (processed, textColumn) = try await service.wordFrames(page, imageWidth: 1280)
        let leftmostGlyph = try XCTUnwrap(processed.frames.map(\.rect.minX).min())

        let column = try XCTUnwrap(textColumn)

        XCTAssertGreaterThan(column.lowerBound, leftmostGlyph + 10)
    }

    // MARK: Private

    private let hafs1421 = ImageDataService(
        ayahInfoDatabase: TestResources.resourceURL("hafs_1421_ayahinfo_1120.db"),
        imagesURL: URL(fileURLWithPath: "/missing-images"),
        ayahMarkerURL: nil
    )
}
