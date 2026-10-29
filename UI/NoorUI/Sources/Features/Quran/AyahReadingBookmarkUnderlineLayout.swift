#if QURAN_SYNC
//
//  AyahReadingBookmarkUnderlineLayout.swift
//

import CoreGraphics

/// Reading bookmark underlines stacked under an ayah marker.
///
/// Every metric is a ratio of the marker's height: the marker already scales with the page,
/// so the underlines look the same on every reading and page size.
struct AyahReadingBookmarkUnderlineLayout {
    // MARK: Lifecycle

    init(markerFrame: CGRect, count: Int) {
        let size = markerFrame.height
        let width = size * Self.widthRatio
        let height = max(Self.minimumHeight, size * Self.heightRatio)
        let spacing = size * Self.spacingRatio
        let top = markerFrame.minY + size * Self.topRatio
        underlineFrames = (0 ..< max(0, count)).map { index in
            CGRect(
                x: markerFrame.midX - width / 2,
                y: top + CGFloat(index) * (height + spacing),
                width: width,
                height: height
            )
        }
        hitFrame = underlineFrames.reduce(markerFrame) { $0.union($1) }
    }

    // MARK: Internal

    /// One underline per reading bookmark, top to bottom.
    let underlineFrames: [CGRect]
    /// The marker and its underlines, which the tap target covers.
    let hitFrame: CGRect

    // MARK: Private

    private static let widthRatio: CGFloat = 0.72
    private static let heightRatio: CGFloat = 0.09
    private static let minimumHeight: CGFloat = 2
    private static let spacingRatio: CGFloat = 0.07
    /// The first underline's top, from the marker's top; leaves a small gap below the marker.
    private static let topRatio: CGFloat = 1.28
}
#endif
