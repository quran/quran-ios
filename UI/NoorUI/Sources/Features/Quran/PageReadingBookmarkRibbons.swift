#if QURAN_SYNC
//
//  PageReadingBookmarkRibbons.swift
//

import Localization
import QuranAnnotations
import QuranKit
import QuranLocalization
import SwiftUI

extension View {
    /// Hangs ribbons for the page's own reading bookmarks behind this page header, at its top right.
    ///
    /// Apply it to the header at the top of the page's scroll content, so the ribbons scroll with the page
    /// and the header text draws over them. Builds nothing when the page has no page bookmarks.
    public func pageReadingBookmarkRibbons(page: Page, slots: [ReadingBookmarkSlot]) -> some View {
        background {
            if !slots.isEmpty {
                PageReadingBookmarkRibbons(page: page, slots: slots)
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

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(Array(slots.enumerated()), id: \.element) { index, slot in
                BookmarkRibbonShape()
                    .fill(slot.swiftUIColor)
                    .frame(width: width, height: ribbonLength(at: index))
                    .zIndex(Double(slots.count - index))
            }
        }
        // One shadow for the whole stack.
        .compositingGroup()
        .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .padding(.trailing, readableInsets.trailing)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        // Always the physical right, whatever the reading direction.
        .environment(\.layoutDirection, .leftToRight)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    var accessibilityLabel: String {
        ([page.localizedName] + slots.map { AyahIndicator.readingBookmark($0).accessibilityLabel })
            .joined(separator: l("list.separator"))
    }

    // MARK: Private

    /// How much shorter each earlier ribbon is, as a ratio of the ribbon width.
    private static let stackStepRatio: CGFloat = 0.45

    @ScaledMetric(relativeTo: .footnote) private var width = 16.0
    @Environment(\.readableInsets) private var readableInsets

    /// The last ribbon reaches from the screen's top edge to the page header's top.
    private func ribbonLength(at index: Int) -> CGFloat {
        let step = width * Self.stackStepRatio
        return max(step, readableInsets.top - CGFloat(slots.count - 1 - index) * step)
    }
}

private struct PageReadingBookmarkRibbonsPreview: View {
    let slots: [ReadingBookmarkSlot]

    var body: some View {
        VStack(spacing: 0) {
            QuranPageHeader(quarterName: "Juz 1", suras: page.suras)
                .pageReadingBookmarkRibbons(page: page, slots: slots)
            Spacer()
            Text("The ribbons hang from the screen's top edge, behind the page header.")
                .font(.footnote)
                .padding()
            Spacer()
        }
        .font(.footnote)
        .populateReadableInsets()
        .themedBackground()
        .ignoresSafeArea()
        .environment(\.themeStyle, .paper)
    }

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
