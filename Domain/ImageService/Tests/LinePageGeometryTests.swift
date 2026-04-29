//
//  LinePageGeometryTests.swift
//
//
//  Created by Mohamed Afifi on 2026-03-29.
//

import LinePagePersistence
import QuranKit
import XCTest
@testable import ImageService

final class LinePageGeometryTests: XCTestCase {
    // MARK: Internal

    func testPortraitLayoutMatchesSizingRules() throws {
        let layout = makeEngine().layout(
            LinePageGeometryInput(
                availableSize: CGSize(width: 400, height: 800),
                orientation: .portrait,
                pageParity: .odd,
                displaySettings: LinePageDisplaySettings(showHeaderFooter: true, showSidelines: false),
                data: makeData(),
                suraHeaderAspectRatio: 0.25
            )
        )

        XCTAssertEqual(layout.contentSize.width, 400)
        XCTAssertEqual(layout.contentSize.height, 800)
        XCTAssertEqual(layout.headerFrame, CGRect(x: 10, y: 0, width: 380, height: 32))
        XCTAssertEqual(layout.pageFrame, CGRect(x: 0, y: 32, width: 400, height: 736))
        XCTAssertEqual(layout.footerFrame, CGRect(x: 10, y: 768, width: 380, height: 32))
        XCTAssertNil(layout.sidelineFrame)
    }

    func testLandscapeLayoutReservesSidelinesOnLeadingEdgeForOddPages() throws {
        let layout = makeEngine().layout(
            LinePageGeometryInput(
                availableSize: CGSize(width: 900, height: 400),
                orientation: .landscape,
                verticalPadding: 20,
                pageParity: .odd,
                displaySettings: LinePageDisplaySettings(showHeaderFooter: true, showSidelines: true),
                data: makeData(
                    sidelines: [
                        .init(targetLine: 3, direction: .up, intrinsicSize: CGSize(width: 50, height: 200)),
                    ]
                ),
                suraHeaderAspectRatio: 0.25
            )
        )

        XCTAssertEqual(layout.headerFrame, CGRect(x: 123, y: 20, width: 744, height: 31))
        XCTAssertEqual(layout.pageFrame, CGRect(x: 102, y: 51, width: 786, height: 1384))
        XCTAssertEqual(layout.footerFrame, CGRect(x: 123, y: 1435, width: 744, height: 31))
        XCTAssertEqual(layout.sidelineFrame, CGRect(x: 0, y: 51, width: 90, height: 1384))
        XCTAssertEqual(layout.contentSize.height, 1501)

        let sideline = try XCTUnwrap(layout.sidelinePlacements.first)
        XCTAssertEqual(sideline.frame.minX, 53.46666666666667, accuracy: 0.001)
        XCTAssertEqual(sideline.frame.minY, 127.8, accuracy: 0.001)
        XCTAssertEqual(sideline.frame.width, 36.53333333333333, accuracy: 0.001)
        XCTAssertEqual(sideline.frame.height, 146.13333333333333, accuracy: 0.001)
    }

    func testHighlightsMarkersAndHeadersUseSharedGeometry() throws {
        let highlightedAyah = try ayah(1, 1)
        let markerAyah = try ayah(1, 2)
        let layout = makeEngine().layout(
            LinePageGeometryInput(
                availableSize: CGSize(width: 400, height: 800),
                orientation: .portrait,
                pageParity: .odd,
                displaySettings: LinePageDisplaySettings(showHeaderFooter: true, showSidelines: false),
                data: makeData(),
                highlights: LinePageHighlightState(
                    highlightedVerses: [highlightedAyah, markerAyah]
                ),
                suraHeaderAspectRatio: 0.25
            )
        )

        XCTAssertEqual(layout.highlightRects.count, 3)

        let firstHighlight = layout.highlightRects[0]
        XCTAssertEqual(firstHighlight.ayah, highlightedAyah)
        XCTAssertEqual(
            firstHighlight.rect,
            expectedHighlightRect(for: makeData().highlightSpans[0], pageFrame: layout.pageFrame)
        )

        let firstMarker = try XCTUnwrap(layout.ayahMarkerPlacements.first { $0.marker.ayah == markerAyah })
        XCTAssertEqual(
            firstMarker.frame,
            expectedMarkerFrame(for: firstMarker.marker, pageFrame: layout.pageFrame)
        )

        let header = try XCTUnwrap(layout.suraHeaderPlacements.first)
        XCTAssertEqual(
            header.frame,
            expectedHeaderFrame(for: header.header, pageFrame: layout.pageFrame, aspectRatio: 0.25)
        )
    }

    func testVerseHitTestingAndSelectionAnchorsFollowAyahSpans() throws {
        let firstAyah = try ayah(1, 1)
        let secondAyah = try ayah(1, 2)
        let layout = makeEngine().layout(
            LinePageGeometryInput(
                availableSize: CGSize(width: 400, height: 800),
                orientation: .portrait,
                pageParity: .odd,
                displaySettings: LinePageDisplaySettings(showHeaderFooter: true, showSidelines: false),
                data: makeData(),
                suraHeaderAspectRatio: 0.25
            )
        )

        let data = makeData()
        let firstRect = try XCTUnwrap(layout.selectionAnchors(for: firstAyah)).start
        let secondRect = try XCTUnwrap(layout.selectionAnchors(for: secondAyah)).start
        let firstPoint = CGPoint(x: firstRect.midX, y: firstRect.midY)
        let secondPoint = CGPoint(x: secondRect.midX, y: secondRect.midY)

        XCTAssertEqual(
            layout.verse(at: firstPoint),
            firstAyah
        )
        XCTAssertEqual(
            layout.verse(at: secondPoint),
            secondAyah
        )
        XCTAssertNil(
            layout.verse(at: CGPoint(x: layout.pageFrame.minX + 40, y: firstPoint.y))
        )
        XCTAssertNil(
            layout.verse(at: CGPoint(x: layout.pageFrame.maxX - 40, y: firstPoint.y))
        )
        XCTAssertNil(layout.verse(at: CGPoint(x: layout.pageFrame.minX - 1, y: layout.pageFrame.minY + 210)))

        let firstAnchors = try XCTUnwrap(layout.selectionAnchors(for: firstAyah))
        let firstSpan = data.highlightSpans[0]
        assertEqual(firstAnchors.start, expectedSelectionRect(for: firstSpan, pageFrame: layout.pageFrame))
        assertEqual(firstAnchors.end, expectedSelectionRect(for: firstSpan, pageFrame: layout.pageFrame))

        let secondAnchors = try XCTUnwrap(layout.selectionAnchors(for: secondAyah))
        assertEqual(
            secondAnchors.start,
            expectedSelectionRect(for: data.highlightSpans[1], pageFrame: layout.pageFrame)
        )
        assertEqual(
            secondAnchors.end,
            expectedSelectionRect(for: data.highlightSpans[2], pageFrame: layout.pageFrame)
        )
    }

    func testVerseHitTestingSupportsLastLine() throws {
        let lastAyah = try ayah(1, 7)
        let data = LinePageGeometryData(
            highlightSpans: [
                .init(ayah: lastAyah, line: 14, left: 0.2, right: 0.8),
            ],
            ayahMarkers: [],
            suraHeaders: [],
            sidelines: []
        )
        let layout = makeEngine().layout(
            LinePageGeometryInput(
                availableSize: CGSize(width: 400, height: 800),
                orientation: .portrait,
                pageParity: .odd,
                displaySettings: LinePageDisplaySettings(showHeaderFooter: true, showSidelines: false),
                data: data,
                suraHeaderAspectRatio: 0.25
            )
        )

        let selectionRect = try XCTUnwrap(layout.selectionAnchors(for: lastAyah)).start
        let point = CGPoint(x: selectionRect.midX, y: selectionRect.midY)
        XCTAssertEqual(layout.verse(at: point), lastAyah)
    }

    func testHiddenHeaderFooterDoesNotReserveChromeSpace() throws {
        let layout = makeEngine().layout(
            LinePageGeometryInput(
                availableSize: CGSize(width: 600, height: 800),
                orientation: .portrait,
                pageParity: .odd,
                displaySettings: LinePageDisplaySettings(showHeaderFooter: false, showSidelines: false),
                data: makeData(),
                suraHeaderAspectRatio: 0.25
            )
        )

        XCTAssertEqual(layout.contentSize.width, 600)
        XCTAssertEqual(layout.contentSize.height, 800)
        XCTAssertEqual(layout.pageFrame, CGRect(x: 50, y: 0, width: 500, height: 800))
        XCTAssertEqual(layout.headerFrame, CGRect(x: 300, y: 0, width: 0, height: 0))
        XCTAssertEqual(layout.footerFrame, CGRect(x: 300, y: 800, width: 0, height: 0))
        XCTAssertNil(layout.sidelineFrame)
    }

    func testNonOverlappingMetricsPlaceLinesInEvenSlots() throws {
        let metrics = LinePageMetrics.naskhLinePages
        let layout = makeEngine().layout(
            LinePageGeometryInput(
                availableSize: CGSize(width: 400, height: 800),
                orientation: .portrait,
                pageParity: .odd,
                displaySettings: LinePageDisplaySettings(showHeaderFooter: true, showSidelines: false),
                data: makeData(metrics: metrics),
                suraHeaderAspectRatio: 0.25
            )
        )

        let slotHeight = layout.pageFrame.height / CGFloat(metrics.lineCount)
        let imageLineHeight = layout.pageFrame.width * CGFloat(metrics.lineHeightRatio)
        let expectedFirstImageY = layout.pageFrame.minY + ((slotHeight - imageLineHeight) / 2)

        assertEqual(
            layout.lineFrames[0].hitFrame,
            CGRect(x: layout.pageFrame.minX, y: layout.pageFrame.minY, width: layout.pageFrame.width, height: slotHeight)
        )
        XCTAssertEqual(layout.lineFrames[0].imageFrame.minY, expectedFirstImageY, accuracy: 0.001)
        XCTAssertEqual(layout.lineFrames[0].imageFrame.height, imageLineHeight, accuracy: 0.001)

        for lineIndex in 0 ..< layout.lineFrames.count - 1 {
            XCTAssertLessThanOrEqual(
                layout.lineFrames[lineIndex].imageFrame.maxY,
                layout.lineFrames[lineIndex + 1].imageFrame.minY
            )
        }
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405
    private let lineHeightRatio: CGFloat = 174 / 1080
    private let suraHeaderWidthRatio: CGFloat = 1038 / 1080

    private func makeEngine() -> LinePageGeometryEngine {
        LinePageGeometryEngine()
    }

    private func makeData(
        metrics: LinePageMetrics = .madaniLinePages(widthParameter: 1080),
        sidelines: [LinePageGeometryData.Sideline] = []
    ) -> LinePageGeometryData {
        LinePageGeometryData(
            metrics: metrics,
            highlightSpans: [
                .init(ayah: try! ayah(1, 1), line: 5, left: 0.2445, right: 0.7555),
                .init(ayah: try! ayah(1, 2), line: 6, left: 0.156, right: 0.844),
                .init(ayah: try! ayah(1, 2), line: 7, left: 0.422, right: 0.811),
            ],
            ayahMarkers: [
                .init(ayah: try! ayah(1, 1), line: 5, centerX: 0.295139, centerY: 0.549879, codePoint: "\u{E900}"),
                .init(ayah: try! ayah(1, 2), line: 6, centerX: 0.205903, centerY: 0.557037, codePoint: "\u{E901}"),
            ],
            suraHeaders: [
                .init(sura: Sura(quran: quran, suraNumber: 1)!, line: 3, centerX: 0.5, centerY: 0.5),
            ],
            sidelines: sidelines
        )
    }

    private func ayah(_ sura: Int, _ ayah: Int) throws -> AyahNumber {
        try XCTUnwrap(AyahNumber(quran: quran, sura: sura, ayah: ayah))
    }

    private func expectedHighlightRect(for span: LinePageHighlightSpan, pageFrame: CGRect) -> CGRect {
        let lineHeight = pageFrame.width * lineHeightRatio
        let lineHeightWithoutOverlap = (pageFrame.height - lineHeight) / 14
        let yStart = (lineHeight - lineHeightWithoutOverlap) / 2
        let y = pageFrame.minY + yStart + (lineHeightWithoutOverlap * CGFloat(span.line))
        return CGRect(
            x: pageFrame.minX + (span.left * pageFrame.width),
            y: y,
            width: ceil((span.right - span.left) * pageFrame.width),
            height: lineHeightWithoutOverlap
        )
    }

    private func expectedMarkerFrame(for marker: LinePageAyahMarker, pageFrame: CGRect) -> CGRect {
        let lineHeight = pageFrame.width * lineHeightRatio
        let markerDimension = pageFrame.width * 0.05
        let yStart = ((pageFrame.height - lineHeight) / 14) * CGFloat(marker.line)
        return CGRect(
            x: pageFrame.minX + (marker.centerX * pageFrame.width) - (markerDimension / 2),
            y: pageFrame.minY + yStart + (marker.centerY * lineHeight) - (markerDimension / 2),
            width: markerDimension,
            height: markerDimension
        )
    }

    private func expectedHeaderFrame(
        for header: LinePageSuraHeader,
        pageFrame: CGRect,
        aspectRatio: CGFloat
    ) -> CGRect {
        let lineHeight = pageFrame.width * lineHeightRatio
        let width = pageFrame.width * suraHeaderWidthRatio
        let height = width * aspectRatio
        let yStart = ((pageFrame.height - lineHeight) / 14) * CGFloat(header.line)
        return CGRect(
            x: pageFrame.minX + (header.centerX * pageFrame.width) - (width / 2),
            y: pageFrame.minY + yStart + (header.centerY * lineHeight) - (height / 2),
            width: width,
            height: height
        )
    }

    private func expectedSelectionRect(for span: LinePageHighlightSpan, pageFrame: CGRect) -> CGRect {
        let hitFrame = expectedHitFrame(lineNumber: span.line, pageFrame: pageFrame)
        return CGRect(
            x: hitFrame.minX + (span.left * pageFrame.width),
            y: hitFrame.minY,
            width: (span.right - span.left) * pageFrame.width,
            height: hitFrame.height
        )
    }

    private func expectedHitFrame(lineNumber: Int, pageFrame: CGRect) -> CGRect {
        let width = Int(pageFrame.width)
        let height = Int(pageFrame.height)
        let lineHeight = Int(CGFloat(width) * lineHeightRatio)
        let lineHeightWithoutOverlap = (height - lineHeight) / 14
        let offset = (lineHeight - lineHeightWithoutOverlap) / 2
        let lineIndex = lineNumber
        let fullLineStart = Int(floor(Double(height - lineHeight) / 14 * Double(lineIndex)))
        return CGRect(
            x: pageFrame.minX,
            y: pageFrame.minY + CGFloat(fullLineStart + offset),
            width: pageFrame.width,
            height: CGFloat(lineHeightWithoutOverlap)
        )
    }

    private func assertEqual(_ lhs: CGRect, _ rhs: CGRect, accuracy: CGFloat = 0.001) {
        XCTAssertEqual(lhs.minX, rhs.minX, accuracy: accuracy)
        XCTAssertEqual(lhs.minY, rhs.minY, accuracy: accuracy)
        XCTAssertEqual(lhs.width, rhs.width, accuracy: accuracy)
        XCTAssertEqual(lhs.height, rhs.height, accuracy: accuracy)
    }
}
