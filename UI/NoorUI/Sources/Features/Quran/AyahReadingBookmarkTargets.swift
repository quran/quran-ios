#if QURAN_SYNC
//
//  AyahReadingBookmarkTargets.swift
//

import Localization
import QuranAnnotations
import QuranKit
import QuranLocalization
import SwiftUI
import UIx

/// Invisible tap targets over bookmarked ayah markers and their underlines.
///
/// Put it above the page image or lines; `AyahReadingBookmarkUnderlines` draws the visible part behind them.
public struct AyahReadingBookmarkTargets: View {
    // MARK: Lifecycle

    public init(
        markers: [AyahMarkerPlacement],
        bookmarks: [AyahNumber: [ReadingBookmarkSlot]],
        onTap: @escaping (AyahNumber, CGPoint) -> Void
    ) {
        self.markers = markers
        self.bookmarks = bookmarks
        self.onTap = onTap
    }

    // MARK: Public

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(markers.bookmarked(by: bookmarks), id: \.ayah) { placement in
                let slots = bookmarks[placement.ayah, default: []]
                let frame = AyahReadingBookmarkUnderlineLayout(markerFrame: placement.frame, count: slots.count).hitFrame

                AyahReadingBookmarkButton(
                    ayah: placement.ayah,
                    slots: slots,
                    size: frame.size,
                    action: { onTap(placement.ayah, $0) }
                )
                .position(x: frame.midX, y: frame.midY)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: Private

    private let markers: [AyahMarkerPlacement]
    private let bookmarks: [AyahNumber: [ReadingBookmarkSlot]]
    private let onTap: (AyahNumber, CGPoint) -> Void
}

/// An invisible button that opens the ayah menu for a bookmarked marker.
struct AyahReadingBookmarkButton: View {
    let ayah: AyahNumber
    let slots: [ReadingBookmarkSlot]
    let size: CGSize
    let action: (CGPoint) -> Void

    var body: some View {
        Button {
            action(CGPoint(x: globalFrame.midX, y: globalFrame.midY))
        } label: {
            Color.clear
                .frame(width: size.width, height: size.height)
                .minimumTouchTarget()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("ayah-indicators-\(ayah.sura.suraNumber)-\(ayah.ayah)")
        .onGlobalFrameChanged { globalFrame = $0 }
    }

    var accessibilityLabel: String {
        ([ayah.localizedName] + slots.map { AyahIndicator.readingBookmark($0).accessibilityLabel })
            .joined(separator: l("list.separator"))
    }

    @State private var globalFrame: CGRect = .zero
}
#endif
