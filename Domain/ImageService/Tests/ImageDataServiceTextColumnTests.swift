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

    func testTextColumnIsTheInkOfPaddedLines() async throws {
        // The 1421 database pads every line to x 14...1106, wider than its ink.
        let bitmap = try PageBitmap.drawn(size: hafs1421ImageSize, glyphs: [
            ([CGRect(x: 40, y: 0, width: 1040, height: hafs1421ImageSize.height)], .black),
        ])

        let column = try await hafs1421.wordFrames(page382, imageWidth: 1120, bitmap: bitmap).textColumn

        XCTAssertEqual(column, 40 ... 1080)
    }

    func testLinesWithoutInkKeepTheirBoxEdges() async throws {
        let bitmap = try PageBitmap.drawn(size: hafs1421ImageSize, glyphs: [])

        let column = try await hafs1421.wordFrames(page382, imageWidth: 1120, bitmap: bitmap).textColumn

        XCTAssertEqual(column, 14 ... 1106)
    }

    func testARealPageTextColumnIsItsInk() async throws {
        // The 1405 boxes overhang the ink by about a pixel: x 101...1187 on page 3.
        let service = ImageDataService(
            ayahInfoDatabase: TestResources.resourceURL("hafs_1405_ayahinfo.db"),
            imagesURL: TestResources.testDataURL.appendingPathComponent("images"),
            ayahMarkerURL: nil
        )

        let column = try await service.imageForPage(Reading.hafs_1405.quran.pages[2]).textColumn

        XCTAssertEqual(column, 102 ... 1186)
    }

    // MARK: Private

    private let hafs1421ImageSize = CGSize(width: 1120, height: 1792)
    private let page382 = Reading.hafs_1421.quran.pages[381]

    private let hafs1421 = ImageDataService(
        ayahInfoDatabase: TestResources.resourceURL("hafs_1421_ayahinfo_1120.db"),
        imagesURL: URL(fileURLWithPath: "/missing-images"),
        ayahMarkerURL: nil
    )
}
