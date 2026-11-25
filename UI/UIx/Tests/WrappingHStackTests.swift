import SwiftUI
import UIKit
import XCTest
@testable import UIx

/// Lays out a large and a small text twice, one pair a row.
@MainActor
final class WrappingHStackTests: XCTestCase {
    func test_firstTextBaseline_putsEachRowOnOneBaseline() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("WrappingHStack needs iOS 16") }
        let layout = try layOut(.firstTextBaseline)

        XCTAssertEqual(layout.items[0].firstBaseline, layout.items[1].firstBaseline, accuracy: 0.01)
        XCTAssertEqual(layout.items[2].firstBaseline, layout.items[3].firstBaseline, accuracy: 0.01)
        XCTAssertEqual(layout.items[2].frame.minY, layout.items[0].frame.maxY, accuracy: 0.01)
        XCTAssertGreaterThan(layout.items[1].frame.minY, layout.items[0].frame.minY)
    }

    func test_reportsFirstRowFirstBaselineAndLastRowLastBaseline() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("WrappingHStack needs iOS 16") }
        let layout = try layOut(.firstTextBaseline)

        XCTAssertEqual(layout.stackFirstBaseline, layout.items[0].firstBaseline, accuracy: 0.01)
        XCTAssertEqual(layout.stackLastBaseline, layout.items[3].lastBaseline, accuracy: 0.01)
        XCTAssertGreaterThan(layout.stackLastBaseline, layout.stackFirstBaseline)
    }

    func test_topCenterAndBottom_placeEachRowAroundItsTallestItem() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("WrappingHStack needs iOS 16") }
        let cases: [(VerticalAlignment, (CGRect) -> CGFloat)] = [(.top, \.minY), (.center, \.midY), (.bottom, \.maxY)]
        for (alignment, guide) in cases {
            let items = try layOut(alignment).items
            let large = items[0].frame
            let small = items[1].frame

            XCTAssertEqual(guide(small), guide(large), accuracy: 0.01, "\(alignment)")
            XCTAssertEqual(items[2].frame.minY, large.maxY, accuracy: 0.01, "\(alignment)")
            XCTAssertEqual(items[3].frame.minY - items[2].frame.minY, small.minY - large.minY, accuracy: 0.01, "\(alignment)")
        }
    }

    // MARK: Private

    private struct Placement {
        var items: [PlacedItem]
        var stackFirstBaseline: CGFloat
        var stackLastBaseline: CGFloat
    }

    @available(iOS 16.0, *)
    private func layOut(_ alignment: VerticalAlignment) throws -> Placement {
        let recorder = PlacementRecorder()
        let texts = [Text("Ag").font(.system(size: 40)), Text("Ag").font(.system(size: 12))]
        let pairWidth = texts.map(width).reduce(0, +)
        let stack = WrappingHStack(
            alignment: Alignment(horizontal: .leading, vertical: alignment),
            horizontalSpacing: 0,
            verticalSpacing: 0
        ) {
            ForEach(0 ..< 4, id: \.self) { index in
                RecordingLayout(id: index, recorder: recorder) {
                    texts[index % 2]
                }
            }
        }
        let content = RecordingLayout(id: -1, recorder: recorder) {
            stack
        }
        .frame(width: pairWidth + 1)
        .environment(\.layoutDirection, .leftToRight)

        let renderer = ImageRenderer(content: content)
        _ = renderer.uiImage

        let items = try (0 ..< 4).map { try XCTUnwrap(recorder.items[$0]) }
        let stackItem = try XCTUnwrap(recorder.items[-1])
        return Placement(items: items, stackFirstBaseline: stackItem.firstBaseline, stackLastBaseline: stackItem.lastBaseline)
    }

    private func width(_ text: Text) -> CGFloat {
        UIHostingController(rootView: text.fixedSize())
            .sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
            .width
    }
}

private struct PlacedItem {
    var frame: CGRect
    var firstBaseline: CGFloat
    var lastBaseline: CGFloat
}

private final class PlacementRecorder {
    var items: [Int: PlacedItem] = [:]
}

/// Records where its only subview is placed, and passes the subview's text baselines through.
@available(iOS 16.0, *)
private struct RecordingLayout: Layout {
    let id: Int
    let recorder: PlacementRecorder

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        subviews[0].sizeThatFits(proposal)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let dimensions = subviews[0].dimensions(in: proposal)
        recorder.items[id] = PlacedItem(
            frame: CGRect(origin: bounds.origin, size: CGSize(width: dimensions.width, height: dimensions.height)),
            firstBaseline: bounds.minY + dimensions[.firstTextBaseline],
            lastBaseline: bounds.minY + dimensions[.lastTextBaseline]
        )
        subviews[0].place(at: bounds.origin, proposal: proposal)
    }

    func explicitAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGFloat? {
        subviews[0].dimensions(in: proposal)[explicit: guide].map { bounds.minY + $0 }
    }
}
