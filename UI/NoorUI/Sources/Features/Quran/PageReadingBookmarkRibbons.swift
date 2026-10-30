#if QURAN_SYNC
//
//  PageReadingBookmarkRibbons.swift
//

import QuranAnnotations
import QuranKit
import QuranLocalization
import SwiftUI

extension View {
    /// Hangs ribbons for the page's own reading bookmarks behind this page header, at its top right.
    ///
    /// Apply it to the header at the top of the page's scroll content, so the ribbons scroll with the page
    /// and the header text draws over them. Builds nothing when the page has no page bookmarks.
    /// Tapping the ribbons calls `onTap` with their frame in global coordinates.
    public func pageReadingBookmarkRibbons(
        page: Page,
        slots: [ReadingBookmarkSlot],
        onTap: @escaping (CGRect) -> Void
    ) -> some View {
        background {
            if !slots.isEmpty {
                PageReadingBookmarkRibbons(page: page, slots: slots, onTap: onTap)
            }
        }
    }
}

/// Ribbons hanging from the page's top edge, which is the screen's top edge, down to the header's top.
/// Earlier slots are shorter and drawn in front, so each later one shows below them
/// and the whole stack ends at the header's top.
struct PageReadingBookmarkRibbons: View {
    // MARK: Internal

    let page: Page
    let slots: [ReadingBookmarkSlot]
    let onTap: (CGRect) -> Void

    var body: some View {
        let lengths = Self.ribbonLengths(count: slots.count, width: width, available: readableInsets.top)
        ZStack(alignment: .top) {
            ForEach(Array(slots.enumerated()), id: \.element) { index, slot in
                BookmarkRibbonShape()
                    .fill(slot.swiftUIColor)
                    .frame(width: width, height: lengths[index])
                    .zIndex(Double(slots.count - index))
            }
        }
        // One shadow for the whole stack.
        .compositingGroup()
        .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
        .readingBookmarkPressed(isPressed, anchor: .top)
        .onGlobalFrameChanged { globalFrame = $0 }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        // Centered on the ribbons, so a larger touch target doesn't move them.
        .overlay {
            Button {
                onTap(globalFrame)
            } label: {
                Color.clear
                    .minimumTouchTarget()
            }
            .buttonStyle(ReadingBookmarkPressReportingStyle { isPressed = $0 })
            .accessibilityLabel(accessibilityLabel)
            .accessibilityIdentifier("page-reading-bookmark-\(page.pageNumber)")
        }
        .padding(.trailing, readableInsets.trailing)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        // Always the physical right, whatever the reading direction.
        .environment(\.layoutDirection, .leftToRight)
        .ignoresSafeArea(edges: .top)
    }

    var accessibilityLabel: String {
        slots.accessibilityLabel(prefixedBy: page.localizedName)
    }

    /// Each ribbon's length, front to back. The last one fills `available`, from the screen's top edge
    /// to the page header's top; each earlier one is a step shorter. The step shrinks when `available`
    /// is short for the ribbon width, so every ribbon in the stack stays visible.
    static func ribbonLengths(count: Int, width: CGFloat, available: CGFloat) -> [CGFloat] {
        let step = min(width * stackStepRatio, available / CGFloat(count + 1))
        return (0 ..< count).map { available - CGFloat(count - 1 - $0) * step }
    }

    // MARK: Private

    /// How much shorter each earlier ribbon is, as a ratio of the ribbon width.
    private static let stackStepRatio: CGFloat = 0.45

    @ScaledMetric(relativeTo: .footnote) private var width = 16.0
    @Environment(\.readableInsets) private var readableInsets
    @State private var isPressed = false
    @State private var globalFrame: CGRect = .zero
}

private struct PageReadingBookmarkRibbonsPreview: View {
    let slots: [ReadingBookmarkSlot]

    var body: some View {
        VStack(spacing: 0) {
            QuranPageHeader(quarterName: "Juz 1", suras: page.suras)
                .pageReadingBookmarkRibbons(page: page, slots: slots) { _ in tapCount += 1 }
            Spacer()
            Text("The ribbons hang from the screen's top edge, behind the page header.")
                .font(.footnote)
                .padding()
            Text(tapCount == 0 ? "Tap the ribbons" : "Ribbons tapped \(tapCount) time\(tapCount == 1 ? "" : "s")")
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
            Spacer()
        }
        .font(.footnote)
        .populateReadableInsets()
        .themedBackground()
        .ignoresSafeArea()
        .environment(\.themeStyle, .paper)
    }

    @State private var tapCount = 0
    private let page = Quran.hafsMadani1405.pages[2]
}

#Preview("Page ribbon") {
    PageReadingBookmarkRibbonsPreview(slots: [.teal])
}

#Preview("Stacked page ribbons") {
    PageReadingBookmarkRibbonsPreview(slots: [.teal, .red])
}

#Preview("Two pages") {
    HStack(spacing: 1) {
        PageReadingBookmarkRibbonsPreview(slots: [.orange])
        PageReadingBookmarkRibbonsPreview(slots: ReadingBookmarkSlot.allCases)
    }
}
#endif
