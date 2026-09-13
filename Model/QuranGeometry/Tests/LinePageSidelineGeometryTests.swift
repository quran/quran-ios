import QuranGeometry
import QuranKit
import XCTest

final class LinePageSidelineGeometryTests: XCTestCase {
    func testEvenPagesReserveTrailingSidelinesAndAlignAssetsTowardText() throws {
        let sidelines = [sideline("a", line: 3, size: CGSize(width: 80, height: 240))]
        let odd = makeLayout(sidelines, parity: .odd)
        let even = makeLayout(sidelines, parity: .even)
        let oddPlacement = try XCTUnwrap(odd.sidelinePlacements.first)
        let evenPlacement = try XCTUnwrap(even.sidelinePlacements.first)

        XCTAssertEqual(odd.pageFrame, CGRect(x: 100, y: 0, width: 900, height: 1600))
        XCTAssertEqual(even.pageFrame, CGRect(x: 0, y: 0, width: 900, height: 1600))
        XCTAssertEqual(even.sidelineFrame, CGRect(x: 900, y: 0, width: 100, height: 1600))
        XCTAssertEqual(oddPlacement.frame.maxX, odd.pageFrame.minX, accuracy: 0.001)
        XCTAssertEqual(evenPlacement.frame.minX, even.pageFrame.maxX, accuracy: 0.001)
        XCTAssertEqual(evenPlacement.frame.size, oddPlacement.frame.size)
        XCTAssertEqual(evenPlacement.frame.minY, oddPlacement.frame.minY)
    }

    func testDownwardCollisionShrinksSidelineToAvailableLines() throws {
        let layout = makeLayout([
            sideline("next", line: 6, size: CGSize(width: 60, height: 200)),
            sideline("first", line: 3, size: CGSize(width: 80, height: 600)),
        ])
        XCTAssertEqual(layout.sidelinePlacements.map(\.sideline.id), ["first", "next"])
        let first = try XCTUnwrap(layout.sidelinePlacements.first).frame
        let next = try XCTUnwrap(layout.sidelinePlacements.last).frame

        XCTAssertEqual(first.minY, 320)
        XCTAssertEqual(first.height, 480)
        XCTAssertEqual(first.width, 64)
        XCTAssertEqual(first.maxY, next.minY)
    }

    func testUpwardCollisionShrinksFromTheTopWithoutOverlappingNextAsset() throws {
        let layout = makeLayout([
            sideline("first", line: 5, direction: .up, size: CGSize(width: 85, height: 850)),
            sideline("next", line: 6, size: CGSize(width: 60, height: 200)),
        ])
        let first = try XCTUnwrap(layout.sidelinePlacements.first).frame
        let next = try XCTUnwrap(layout.sidelinePlacements.last).frame

        XCTAssertEqual(first.minY, 0)
        XCTAssertEqual(first.height, 800)
        XCTAssertEqual(first.width, 80)
        XCTAssertEqual(first.maxY, next.minY)
    }

    func testSmallCollisionKeepsIntrinsicSizeAndMovesAssetAboveNext() throws {
        let layout = makeLayout([
            sideline("first", line: 3, size: CGSize(width: 80, height: 500)),
            sideline("next", line: 6, size: CGSize(width: 60, height: 200)),
        ])
        let first = try XCTUnwrap(layout.sidelinePlacements.first).frame
        let next = try XCTUnwrap(layout.sidelinePlacements.last).frame

        // A 20-point reduction is below the 25-source-pixel resize threshold.
        XCTAssertEqual(first.size, CGSize(width: 80, height: 500))
        XCTAssertEqual(first.minY, 300)
        XCTAssertEqual(first.maxY, next.minY)
    }

    func testLastSidelineMovesUpToStayWithinPage() throws {
        let layout = makeLayout([sideline("last", line: 10, size: CGSize(width: 80, height: 240))])
        let frame = try XCTUnwrap(layout.sidelinePlacements.first).frame

        XCTAssertEqual(frame.minY, 1320)
        XCTAssertEqual(frame.height, 280)
        XCTAssertEqual(frame.maxY, layout.pageFrame.maxY)
    }

    func testWideAssetFitsColumnWhilePreservingAspectRatio() throws {
        let layout = makeLayout([sideline("wide", line: 3, size: CGSize(width: 200, height: 400))])
        let frame = try XCTUnwrap(layout.sidelinePlacements.first).frame

        XCTAssertEqual(frame, CGRect(x: 0, y: 320, width: 100, height: 200))
    }

    func testSameLineAssetsSortByIntrinsicHeightAndRetainIdentity() {
        let layout = makeLayout([
            sideline("tall", line: 5, size: CGSize(width: 80, height: 400)),
            sideline("short", line: 5, size: CGSize(width: 80, height: 200)),
        ])

        XCTAssertEqual(layout.sidelinePlacements.map(\.sideline.id), ["short", "tall"])
    }

    func testHiddenSidelinesDoNotReserveSpaceOrProducePlacements() {
        let layout = makeLayout(
            [sideline("a", line: 3, size: CGSize(width: 80, height: 240))],
            showSidelines: false
        )

        XCTAssertNil(layout.sidelineFrame)
        XCTAssertTrue(layout.sidelinePlacements.isEmpty)
        XCTAssertEqual(layout.pageFrame.width, 1000)
    }

    private func sideline(
        _ id: String,
        line: Int,
        direction: LinePageSidelineDirection = .down,
        size: CGSize
    ) -> LinePageGeometryData.Sideline {
        .init(id: id, targetLine: line, direction: direction, intrinsicSize: size)
    }

    private func makeLayout(
        _ sidelines: [LinePageGeometryData.Sideline],
        parity: LinePageParity = .odd,
        showSidelines: Bool = true
    ) -> LinePageLayout {
        // A 900-point page at source scale, with ten 160-point line slots.
        let data = LinePageGeometryData(
            metrics: .madaniLinePages(widthParameter: 900),
            lineCount: 10,
            highlightSpans: [],
            ayahMarkers: [],
            suraHeaders: [],
            sidelines: sidelines
        )
        return LinePageGeometryEngine().layout(LinePageGeometryInput(
            availableSize: CGSize(width: 1000, height: 1600),
            orientation: .portrait,
            pageParity: parity,
            displaySettings: LinePageDisplaySettings(showHeaderFooter: false, showSidelines: showSidelines),
            data: data,
            suraHeaderAspectRatio: 0.25
        ))
    }
}
