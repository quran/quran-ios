//
//  LinePageAssetServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2026-03-28.
//

import QuranKit
import SystemDependencies
import UIKit
import XCTest
@testable import ImageService

final class LinePageAssetServiceTests: XCTestCase {
    // MARK: Internal

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: rootURL)
    }

    func testRequiredStructureReturnsAvailableWhenDatabaseAndFirstLineExist() throws {
        try createAyahInfoDatabase()
        try createPage(pageNumber: 1, missingLines: Set(2 ... 15))

        let service = makeService(requiredPageNumbers: [1, 2])

        XCTAssertTrue(service.hasRequiredStructure())
    }

    func testRequiredStructureReturnsUnavailableWhenFirstLineIsMissing() throws {
        try createAyahInfoDatabase()
        try createPage(pageNumber: 1, missingLines: [1])

        let service = makeService(requiredPageNumbers: [1, 2])

        XCTAssertFalse(service.hasRequiredStructure())
    }

    func testRequiredStructureChecksFirstConfiguredVisiblePage() throws {
        try createAyahInfoDatabase()
        try createPage(pageNumber: 1, missingLines: Set(2 ... 15))
        try createPage(pageNumber: 2, missingLines: Set(2 ... 15))

        let service = makeService(requiredPageNumbers: [2, 3])

        XCTAssertTrue(service.hasRequiredStructure())
    }

    func testRequiredStructureReturnsUnavailableWhenFirstConfiguredVisiblePageIsMissing() throws {
        try createAyahInfoDatabase()
        try createPage(pageNumber: 1, missingLines: Set(2 ... 15))

        let service = makeService(requiredPageNumbers: [2, 3])

        XCTAssertFalse(service.hasRequiredStructure())
    }

    func testAssetsForPageReturnsAvailableWhenSidelinesAreMissing() async throws {
        try createAyahInfoDatabase()
        try createPage(pageNumber: 1)

        let service = makeService(requiredPageNumbers: [1])
        let page = try XCTUnwrap(Page(quran: .hafsMadani1440, pageNumber: 1))

        switch await service.assetsForPage(page) {
        case .available(let assets):
            XCTAssertEqual(assets.lines.count, 15)
            XCTAssertTrue(assets.sidelines.isEmpty)
            XCTAssertEqual(assets.ayahInfoDatabaseURL.lastPathComponent, "ayahinfo_1440.db")
        case .unavailable:
            XCTFail("Expected available assets")
        }
    }

    func testAssetsForPageUsesMetricsLineCount() async throws {
        try createAyahInfoDatabase()
        try createPage(pageNumber: 1, lineCount: 2)

        let service = makeService(
            metrics: LinePageMetrics(
                widthParameter: 1440,
                lineCount: 2,
                lineHeightRatio: 174 / 1080,
                intrinsicLineHeight: 174,
                allowLineOverlap: true
            ),
            requiredPageNumbers: [1]
        )
        let page = try XCTUnwrap(Page(quran: .hafsMadani1440, pageNumber: 1))

        switch await service.assetsForPage(page) {
        case .available(let assets):
            XCTAssertEqual(assets.lines.map(\.lineNumber), [1, 2])
        case .unavailable:
            XCTFail("Expected available assets")
        }
    }

    func testAssetsForPageDecodesLineAndSidelineImagesIntoBitmaps() async throws {
        try createAyahInfoDatabase()
        try createPage(pageNumber: 1, includeSidelines: true, png: palettePNGWithTransparency())

        let service = makeService(requiredPageNumbers: [1])
        let page = try XCTUnwrap(Page(quran: .hafsMadani1440, pageNumber: 1))

        switch await service.assetsForPage(page) {
        case .available(let assets):
            let images = assets.lines.map(\.image) + assets.sidelines.map(\.image)
            XCTAssertEqual(images.count, 16)
            for image in images {
                // A lazily decoded PNG stays in ImageIO's premultiplied-last layout until first drawn.
                let cgImage = try XCTUnwrap(image.cgImage)
                XCTAssertEqual(cgImage.alphaInfo, .premultipliedFirst)
                XCTAssertEqual(cgImage.byteOrderInfo, .order32Little)
                XCTAssertEqual(image.size, CGSize(width: 8, height: 2))
                XCTAssertEqual(try bgraPixel(cgImage, x: 0, y: 1)[3], 0)
                XCTAssertEqual(try bgraPixel(cgImage, x: 1, y: 1), [0, 0, 0, 255])
            }
        case .unavailable:
            XCTFail("Expected available assets")
        }
    }

    // MARK: Private

    private lazy var rootURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)

    private func makeService(
        metrics: LinePageMetrics = .madaniLinePages(widthParameter: 1440),
        requiredPageNumbers: [Int]
    ) -> LinePageAssetService {
        LinePageAssetService(
            readingDirectory: rootURL,
            metrics: metrics,
            requiredPageNumbers: requiredPageNumbers,
            ayahMarkerURL: nil,
            fileSystem: DefaultFileSystem()
        )
    }

    private func createAyahInfoDatabase() throws {
        let databasesDirectory = rootURL
            .appendingPathComponent("images_1440")
            .appendingPathComponent("databases", isDirectory: true)
        try FileManager.default.createDirectory(at: databasesDirectory, withIntermediateDirectories: true, attributes: nil)
        FileManager.default.createFile(
            atPath: databasesDirectory.appendingPathComponent("ayahinfo_1440.db").path,
            contents: Data("db".utf8)
        )
    }

    private func createPage(
        pageNumber: Int,
        lineCount: Int = 15,
        missingLines: Set<Int> = [],
        includeSidelines: Bool = false,
        png: Data? = nil
    ) throws {
        let png = try png ?? makePNG()
        let pageDirectory = rootURL
            .appendingPathComponent("images_1440")
            .appendingPathComponent("width_1440")
            .appendingPathComponent(String(pageNumber), isDirectory: true)
        try FileManager.default.createDirectory(at: pageDirectory, withIntermediateDirectories: true, attributes: nil)

        for lineNumber in 1 ... lineCount where !missingLines.contains(lineNumber) {
            try png.write(to: pageDirectory.appendingPathComponent("\(lineNumber).png"))
        }

        if includeSidelines {
            let sidelinesDirectory = pageDirectory.appendingPathComponent("sidelines", isDirectory: true)
            try FileManager.default.createDirectory(at: sidelinesDirectory, withIntermediateDirectories: true, attributes: nil)
            try png.write(to: sidelinesDirectory.appendingPathComponent("3_up.png"))
        }
    }

    private func makePNG() throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        let image = renderer.image { context in
            UIColor.black.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        return try XCTUnwrap(image.pngData())
    }

    /// An 8x2 PNG with an 8-bit palette and a transparent entry (`tRNS`), the format line-page images ship in:
    /// even columns are the transparent white entry, odd columns opaque black ink.
    private func palettePNGWithTransparency() throws -> Data {
        try XCTUnwrap(Data(
            base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAgAAAACCAMAAABSSm3fAAAABlBMVEX///8AAABVwtN+AAAAAXRSTlMAQObYZgAAAA5JREFUeJxjYGCEQhgDAABWAAmVf2ZGAAAAAElFTkSuQmCC"
        ))
    }

    /// The BGRA bytes of the pixel at `x`, `y` in a 32-bit little-endian bitmap.
    private func bgraPixel(_ image: CGImage, x: Int, y: Int) throws -> [UInt8] {
        let data = try XCTUnwrap(image.dataProvider?.data as Data?)
        let offset = y * image.bytesPerRow + x * 4
        return Array(data[offset ..< offset + 4])
    }
}
