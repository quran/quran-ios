//
//  LinePagePersistenceTests.swift
//
//
//  Created by Mohamed Afifi on 2026-03-28.
//

import QuranKit
import XCTest
@testable import LinePagePersistence

final class LinePagePersistenceTests: XCTestCase {
    // MARK: Internal

    func testHighlightSpans() async throws {
        let page = try XCTUnwrap(Page(quran: quran, pageNumber: 1))
        let persistence = makePersistence()

        let highlights = try await persistence.highlightSpans(page)
        let expected = [
            (ayah: 1, line: 5, left: 0.2445, right: 0.7555),
            (ayah: 2, line: 6, left: 0.156, right: 0.844),
            (ayah: 3, line: 7, left: 0.534356, right: 0.936),
            (ayah: 4, line: 7, left: 0.064, right: 0.534356),
            (ayah: 5, line: 8, left: 0.248196, right: 0.945),
            (ayah: 6, line: 8, left: 0.055, right: 0.248196),
            (ayah: 6, line: 9, left: 0.476419, right: 0.9155),
            (ayah: 7, line: 9, left: 0.0845, right: 0.476419),
            (ayah: 7, line: 10, left: 0.1645, right: 0.8355),
            (ayah: 7, line: 11, left: 0.295, right: 0.705),
        ]

        XCTAssertEqual(highlights.count, expected.count)
        for (actual, expected) in zip(highlights, expected) {
            XCTAssertEqual(actual.ayah, AyahNumber(quran: quran, sura: 1, ayah: expected.ayah))
            XCTAssertEqual(actual.line, expected.line)
            XCTAssertEqual(actual.left, expected.left, accuracy: 0.000001)
            XCTAssertEqual(actual.right, expected.right, accuracy: 0.000001)
        }
    }

    func testAyahMarkers() async throws {
        let page = try XCTUnwrap(Page(quran: quran, pageNumber: 1))
        let persistence = makePersistence()

        let markers = try await persistence.ayahMarkers(page)
        let expected = [
            (ayah: 1, line: 5, centerX: 0.295139, centerY: 0.549879, codePoint: "\u{E900}"),
            (ayah: 2, line: 6, centerX: 0.205903, centerY: 0.557037, codePoint: "\u{E901}"),
            (ayah: 3, line: 7, centerX: 0.561856, centerY: 0.551724, codePoint: "\u{E902}"),
            (ayah: 4, line: 7, centerX: 0.113443, centerY: 0.551724, codePoint: "\u{E903}"),
            (ayah: 5, line: 8, centerX: 0.275696, centerY: 0.550029, codePoint: "\u{E904}"),
            (ayah: 6, line: 9, centerX: 0.503919, centerY: 0.547455, codePoint: "\u{E905}"),
            (ayah: 7, line: 11, centerX: 0.345189, centerY: 0.549725, codePoint: "\u{E906}"),
        ]

        XCTAssertEqual(markers.count, expected.count)
        for (actual, expected) in zip(markers, expected) {
            XCTAssertEqual(actual.ayah, AyahNumber(quran: quran, sura: 1, ayah: expected.ayah))
            XCTAssertEqual(actual.line, expected.line)
            XCTAssertEqual(actual.centerX, expected.centerX, accuracy: 0.000001)
            XCTAssertEqual(actual.centerY, expected.centerY, accuracy: 0.000001)
            XCTAssertEqual(actual.codePoint, expected.codePoint)
        }
    }

    func testSuraHeaders() async throws {
        let page = try XCTUnwrap(Page(quran: quran, pageNumber: 1))
        let persistence = makePersistence()

        let headers = try await persistence.suraHeaders(page)

        XCTAssertEqual(headers, [
            LinePageSuraHeader(
                sura: Sura(quran: quran, suraNumber: 1)!,
                line: 3,
                centerX: 0.5,
                centerY: 0.5
            ),
        ])
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405

    private func makePersistence() -> GRDBLinePagePersistence {
        GRDBLinePagePersistence(fileURL: fixtureURL(named: "line_page_ayahinfo"))
    }

    private func fixtureURL(named name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: "db")!
    }
}
