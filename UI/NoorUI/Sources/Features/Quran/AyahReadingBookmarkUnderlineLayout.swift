#if QURAN_SYNC
//
//  AyahReadingBookmarkUnderlineLayout.swift
//

import CoreGraphics

/// A reading bookmark underline under an ayah marker, split into one equal segment per bookmark.
///
/// Every metric is a ratio of the marker's height: the marker already scales with the page,
/// so the underline looks the same on every reading and page size.
/// The line's size and position don't depend on the bookmark count.
struct AyahReadingBookmarkUnderlineLayout {
    // MARK: Lifecycle

    init(markerFrame: CGRect, count: Int) {
        let size = markerFrame.height
        guard count > 0, size > 0 else {
            lineFrame = nil
            gap = 0
            hitFrame = markerFrame
            return
        }
        let width = size * Self.widthRatio
        let line = CGRect(
            x: markerFrame.midX - width / 2,
            y: markerFrame.minY + size * Self.topRatio,
            width: width,
            height: max(Self.minimumHeight, size * Self.heightRatio)
        )
        lineFrame = line
        // Keeps the gaps narrower than the line, so every segment has a positive width.
        gap = min(max(Self.minimumGap, size * Self.gapRatio), width / CGFloat(count))
        hitFrame = markerFrame.union(line)
    }

    // MARK: Internal

    /// The whole underline, or `nil` without bookmarks or a sized marker.
    let lineFrame: CGRect?
    /// The space between adjacent segments; the line's ends have none.
    let gap: CGFloat
    /// The marker and its underline, which the tap target covers.
    let hitFrame: CGRect

    // MARK: Private

    /// Wider than the marker, by a tenth of the marker's height past it on each side.
    private static let widthRatio: CGFloat = 1.2
    private static let heightRatio: CGFloat = 0.12
    private static let minimumHeight: CGFloat = 2.5
    private static let gapRatio: CGFloat = 0.05
    private static let minimumGap: CGFloat = 1
    /// The line's top, from the marker's top; leaves a thin gap so it hugs the marker.
    private static let topRatio: CGFloat = 1.15
}
#endif
