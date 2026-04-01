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

    func testReadingAvailabilityReturnsAvailableWhenAllLinesExist() throws {
        try createAyahInfoDatabase()
        try createPage(pageNumber: 1)
        try createPage(pageNumber: 2)

        let service = makeService(requiredPageNumbers: [1, 2])

        XCTAssertTrue(service.isReadingAvailable())
    }

    func testReadingAvailabilityReturnsUnavailableWhenALineIsMissing() throws {
        try createAyahInfoDatabase()
        try createPage(pageNumber: 1)
        try createPage(pageNumber: 2, missingLines: [7])

        let service = makeService(requiredPageNumbers: [1, 2])

        XCTAssertFalse(service.isReadingAvailable())
    }

    func testAssetsForPageReturnsAvailableWhenSidelinesAreMissing() throws {
        try createAyahInfoDatabase()
        try createPage(pageNumber: 1)

        let service = makeService(requiredPageNumbers: [1])
        let page = try XCTUnwrap(Page(quran: .hafsMadani1440, pageNumber: 1))

        switch service.assetsForPage(page) {
        case .available(let assets):
            XCTAssertEqual(assets.lines.count, 15)
            XCTAssertTrue(assets.sidelines.isEmpty)
            XCTAssertEqual(assets.ayahInfoDatabaseURL.lastPathComponent, "ayahinfo_1440.db")
        case .unavailable:
            XCTFail("Expected available assets")
        }
    }

    func testReadingSelectionGuardKeepsCurrentReadingWhen1441IsUnavailable() {
        let guardrail = ReadingSelectionGuard { reading in
            reading != .hafs_1441
        }

        let resolved = guardrail.resolvedReading(current: .hafs_1405, requested: .hafs_1441)

        XCTAssertEqual(resolved, .hafs_1405)
    }

    func testReadingSelectionGuardAllows1441WhenItIsAvailable() {
        let guardrail = ReadingSelectionGuard { _ in true }

        let resolved = guardrail.resolvedReading(current: .hafs_1405, requested: .hafs_1441)

        XCTAssertEqual(resolved, .hafs_1441)
    }

    // MARK: Private

    private lazy var rootURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)

    private func makeService(requiredPageNumbers: [Int]) -> LinePageAssetService {
        LinePageAssetService(
            readingDirectory: rootURL,
            widthParameter: 1440,
            requiredPageNumbers: requiredPageNumbers,
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

    private func createPage(pageNumber: Int, missingLines: Set<Int> = [], includeSidelines: Bool = false) throws {
        let pageDirectory = rootURL
            .appendingPathComponent("images_1440")
            .appendingPathComponent("width_1440")
            .appendingPathComponent(String(pageNumber), isDirectory: true)
        try FileManager.default.createDirectory(at: pageDirectory, withIntermediateDirectories: true, attributes: nil)

        for lineNumber in 1 ... 15 where !missingLines.contains(lineNumber) {
            try makePNG().write(to: pageDirectory.appendingPathComponent("\(lineNumber).png"))
        }

        if includeSidelines {
            let sidelinesDirectory = pageDirectory.appendingPathComponent("sidelines", isDirectory: true)
            try FileManager.default.createDirectory(at: sidelinesDirectory, withIntermediateDirectories: true, attributes: nil)
            try makePNG().write(to: sidelinesDirectory.appendingPathComponent("3_up.png"))
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
}
