import QuranGeometry
import QuranKit
import XCTest

final class IndoPakLinePageGeometryTests: XCTestCase {
    func testHighlightsFillOnlySelectedAyahSpansInTheirLineSlots() {
        let verse = ayah(2)
        let layout = makeLayout(highlightedVerses: [verse])

        // At source width, each 148-point image is centered in a 160-point slot.
        XCTAssertEqual(layout.pageFrame, CGRect(x: 0, y: 0, width: 1342, height: 2400))
        XCTAssertEqual(layout.highlightRects.map(\.ayah), [verse, verse])
        XCTAssertEqual(layout.highlightRects.map(\.rect), [
            CGRect(x: 335.5, y: 160, width: 671, height: 160),
            CGRect(x: 0, y: 0, width: 671, height: 160),
        ])
        XCTAssertEqual(layout.lineFrames[1].imageFrame, CGRect(x: 0, y: 166, width: 1342, height: 148))
    }

    func testMarkerUsesImageCoordinatesWithinItsSlot() throws {
        let layout = makeLayout()
        let placement = try XCTUnwrap(layout.ayahMarkerPlacements.first)

        XCTAssertEqual(placement.marker.ayah, ayah(2))
        XCTAssertEqual(placement.frame.midX, 335.5, accuracy: 0.001)
        // Three quarters down the second line image, including its six-point top inset.
        XCTAssertEqual(placement.frame.midY, 277, accuracy: 0.001)
        XCTAssertEqual(placement.frame.width, 67.1, accuracy: 0.001)
        XCTAssertEqual(placement.frame.height, placement.frame.width)
    }

    func testSuraHeaderIsCenteredOnItsLineImageWithRequestedAspectRatio() throws {
        let layout = makeLayout()
        let placement = try XCTUnwrap(layout.suraHeaderPlacements.first)

        XCTAssertEqual(placement.frame.midX, 671, accuracy: 0.001)
        XCTAssertEqual(placement.frame.midY, 400, accuracy: 0.001)
        XCTAssertEqual(placement.frame.width, 1289.811111, accuracy: 0.001)
        XCTAssertEqual(placement.frame.height / placement.frame.width, 0.25, accuracy: 0.001)
    }

    func testSelectionOrdersContinuedAyahSpansByLine() throws {
        let layout = makeLayout()
        let anchors = try XCTUnwrap(layout.selectionAnchors(for: ayah(2)))

        // The input deliberately supplies this ayah's second line before its first.
        XCTAssertEqual(anchors.start, CGRect(x: 0, y: 0, width: 671, height: 160))
        XCTAssertEqual(anchors.end, CGRect(x: 335.5, y: 160, width: 671, height: 160))
        XCTAssertNil(layout.selectionAnchors(for: ayah(7)))
    }

    func testHitTestingDistinguishesSameLineAyahsAndIncludesSlotPaddingAndLastLine() {
        let layout = makeLayout()

        XCTAssertEqual(layout.verse(at: CGPoint(x: 1000, y: 80)), ayah(1))
        XCTAssertEqual(layout.verse(at: CGPoint(x: 300, y: 80)), ayah(2))
        XCTAssertEqual(layout.verse(at: CGPoint(x: 500, y: 161)), ayah(2))
        XCTAssertEqual(layout.verse(at: CGPoint(x: 500, y: 319)), ayah(2))
        XCTAssertEqual(layout.verse(at: CGPoint(x: 500, y: 2399)), ayah(3))
        XCTAssertNil(layout.verse(at: CGPoint(x: 100, y: 200)))
        XCTAssertNil(layout.verse(at: CGPoint(x: 500, y: 400)))
        XCTAssertNil(layout.verse(at: CGPoint(x: -1, y: 80)))
        XCTAssertNil(layout.verse(at: CGPoint(x: 500, y: 2401)))
    }

    func testNoHighlightedVersesLeavesMarkersAndHeadersAvailable() {
        let layout = makeLayout()

        XCTAssertTrue(layout.highlightRects.isEmpty)
        XCTAssertEqual(layout.ayahMarkerPlacements.count, 1)
        XCTAssertEqual(layout.suraHeaderPlacements.count, 1)
    }

    private func makeLayout(highlightedVerses: Set<AyahNumber> = []) -> LinePageLayout {
        let data = LinePageGeometryData(
            metrics: .indoPakLinePages,
            highlightSpans: [
                .init(ayah: ayah(2), line: 1, left: 0.25, right: 0.75),
                .init(ayah: ayah(1), line: 0, left: 0.5, right: 1),
                .init(ayah: ayah(2), line: 0, left: 0, right: 0.5),
                .init(ayah: ayah(3), line: 14, left: 0.25, right: 0.75),
            ],
            ayahMarkers: [
                .init(ayah: ayah(2), line: 1, centerX: 0.25, centerY: 0.75, codePoint: "\u{E901}"),
            ],
            suraHeaders: [
                .init(sura: Sura(quran: .hafsMadani1405, suraNumber: 1)!, line: 2, centerX: 0.5, centerY: 0.5),
            ],
            sidelines: []
        )
        return LinePageGeometryEngine().layout(LinePageGeometryInput(
            availableSize: CGSize(width: 1342, height: 2400),
            orientation: .portrait,
            pageParity: .odd,
            displaySettings: LinePageDisplaySettings(showHeaderFooter: false),
            data: data,
            highlights: LinePageHighlightState(highlightedVerses: highlightedVerses),
            suraHeaderAspectRatio: 0.25
        ))
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: number)!
    }
}
