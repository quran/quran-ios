//
//  ContentLineViewSnapshotTests.swift
//
//
//  Created by Mohamed Afifi on 2026-03-29.
//

import ImageService
import NoorUI
import QuranAnnotations
import QuranKit
import SnapshotTesting
import SwiftUI
import UIKit
import XCTest
@testable import QuranImageFeature

@MainActor
final class ContentLineViewSnapshotTests: XCTestCase {
    // MARK: Internal

    func testPlainPage() {
        assertLineSnapshot(
            layout: makeLayout(
                data: LinePageGeometryData(
                    highlightSpans: [],
                    ayahMarkers: [],
                    suraHeaders: [],
                    sidelines: []
                )
            ),
            highlightColorsByVerse: [:]
        )
    }

    func testPageWithSuraHeaders() {
        assertLineSnapshot(
            layout: makeLayout(
                data: LinePageGeometryData(
                    highlightSpans: [],
                    ayahMarkers: [],
                    suraHeaders: [
                        .init(sura: Sura(quran: quran, suraNumber: 1)!, line: 3, centerX: 0.5, centerY: 0.5),
                    ],
                    sidelines: []
                )
            ),
            highlightColorsByVerse: [:]
        )
    }

    func testPageWithAyahMarkers() {
        let firstAyah = AyahNumber(quran: quran, sura: 1, ayah: 1)!
        let secondAyah = AyahNumber(quran: quran, sura: 1, ayah: 2)!
        assertLineSnapshot(
            layout: makeLayout(
                data: LinePageGeometryData(
                    highlightSpans: [],
                    ayahMarkers: [
                        .init(ayah: firstAyah, line: 5, centerX: 0.24, centerY: 0.56, codePoint: "\u{E900}"),
                        .init(ayah: secondAyah, line: 6, centerX: 0.77, centerY: 0.58, codePoint: "\u{E901}"),
                    ],
                    suraHeaders: [],
                    sidelines: []
                )
            ),
            highlightColorsByVerse: [:]
        )
    }

    func testPageWithHighlightOverlays() {
        let ayah1 = AyahNumber(quran: quran, sura: 1, ayah: 1)!
        let ayah2 = AyahNumber(quran: quran, sura: 1, ayah: 2)!
        let ayah3 = AyahNumber(quran: quran, sura: 1, ayah: 3)!
        let ayah4 = AyahNumber(quran: quran, sura: 1, ayah: 4)!

        var highlights = QuranHighlights()
        highlights.shareVerses = [ayah1]
        highlights.readingVerses = [ayah2]
        highlights.searchVerses = [ayah3]
        highlights.noteVerses = [
            ayah4: Note(verses: [ayah4], modifiedDate: .distantPast, note: nil, color: .yellow),
        ]

        assertLineSnapshot(
            layout: makeLayout(
                data: LinePageGeometryData(
                    highlightSpans: [
                        .init(ayah: ayah1, line: 5, left: 0.18, right: 0.84),
                        .init(ayah: ayah2, line: 6, left: 0.24, right: 0.78),
                        .init(ayah: ayah3, line: 7, left: 0.34, right: 0.88),
                        .init(ayah: ayah4, line: 8, left: 0.14, right: 0.62),
                    ],
                    ayahMarkers: [],
                    suraHeaders: [],
                    sidelines: []
                )
            ),
            highlightColorsByVerse: highlights.versesByHighlights().mapValues { Color($0) }
        )
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405
    private let snapshotSize = CGSize(width: 390, height: 844)
    private let record = ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] != nil

    private var suraHeaderAspectRatio: CGFloat {
        let image = NoorImage.suraHeader.uiImage
        return image.size.height / image.size.width
    }

    private func assertLineSnapshot(
        layout: LinePageLayout,
        highlightColorsByVerse: [AyahNumber: Color],
        testName: String = #function
    ) {
        let lineImages = makeLineImages()
        let view = ContentLineViewBody(
            page: quran.pages[0],
            layout: layout,
            scrollToVerse: nil,
            highlightColorsByVerse: highlightColorsByVerse,
            imageRenderingMode: .tinted,
            imageForLine: { lineNumber in
                lineImages[lineNumber]
            },
            onGlobalFrameChange: { _ in }
        )
        .environment(\.themeStyle, .original)
        .environment(\.locale, Locale(identifier: "en"))

        assertSnapshot(
            matching: view,
            as: .image(
                layout: .fixed(width: snapshotSize.width, height: snapshotSize.height),
                traits: .init(userInterfaceStyle: .light)
            ),
            record: record,
            testName: testName
        )
    }

    private func makeLayout(data: LinePageGeometryData) -> LinePageLayout {
        LinePageGeometryEngine().layout(
            LinePageGeometryInput(
                availableSize: snapshotSize,
                orientation: .portrait,
                pageParity: .odd,
                displaySettings: LinePageDisplaySettings(showHeaderFooter: true, showSidelines: false),
                data: data,
                suraHeaderAspectRatio: suraHeaderAspectRatio
            )
        )
    }

    private func makeLineImages() -> [Int: UIImage] {
        Dictionary(uniqueKeysWithValues: (1 ... 15).map { ($0, makeLineImage(lineNumber: $0)) })
    }

    private func makeLineImage(lineNumber: Int) -> UIImage {
        let size = CGSize(width: 1080, height: 174)
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            let context = rendererContext.cgContext
            context.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: size))

            context.setFillColor(UIColor.black.cgColor)
            let strokeHeight: CGFloat = 10
            let baseY = CGFloat(18 + ((lineNumber + 1) % 3) * 12)
            let segments = [
                CGRect(x: 120, y: baseY, width: 260, height: strokeHeight),
                CGRect(x: 460, y: baseY + 32, width: 190, height: strokeHeight),
                CGRect(x: 710, y: baseY + 14, width: 230, height: strokeHeight),
            ]
            segments.forEach { context.fill($0) }
        }
    }
}
