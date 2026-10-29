#if QURAN_SYNC
//
//  AyahReadingBookmarkTargets.swift
//

import QuranAnnotations
import QuranKit
import QuranLocalization
import SwiftUI
import UIx

/// Invisible tap targets over bookmarked ayah markers and their underlines.
///
/// Put it above the page image or lines; `AyahReadingBookmarkUnderlines` draws the visible part behind them.
/// It sets `pressedAyah` while a target is pressed; pass the same state to the underlines.
public struct AyahReadingBookmarkTargets: View {
    // MARK: Lifecycle

    public init(
        markers: [AyahMarkerPlacement],
        bookmarks: [AyahNumber: [ReadingBookmarkSlot]],
        pressedAyah: Binding<AyahNumber?>,
        onTap: @escaping (AyahNumber, CGPoint) -> Void
    ) {
        self.markers = markers
        self.bookmarks = bookmarks
        _pressedAyah = pressedAyah
        self.onTap = onTap
    }

    // MARK: Public

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(markers.bookmarked(by: bookmarks), id: \.ayah) { placement in
                let slots = bookmarks[placement.ayah, default: []]
                let layout = AyahReadingBookmarkUnderlineLayout(markerFrame: placement.frame, count: slots.count)
                // Like the underline, waits for the marker's first measure.
                if layout.lineFrame != nil {
                    let frame = layout.hitFrame
                    AyahReadingBookmarkButton(
                        ayah: placement.ayah,
                        slots: slots,
                        size: frame.size,
                        onPressedChange: { isPressed in
                            pressedAyah = Self.pressedAyah(pressedAyah, after: placement.ayah, isPressed: isPressed)
                        },
                        action: { onTap(placement.ayah, $0) }
                    )
                    .position(x: frame.midX, y: frame.midY)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: Internal

    /// The pressed ayah once `ayah`'s target becomes pressed or released.
    static func pressedAyah(_ current: AyahNumber?, after ayah: AyahNumber, isPressed: Bool) -> AyahNumber? {
        if isPressed {
            return ayah
        }
        return current == ayah ? nil : current
    }

    // MARK: Private

    @Binding private var pressedAyah: AyahNumber?

    private let markers: [AyahMarkerPlacement]
    private let bookmarks: [AyahNumber: [ReadingBookmarkSlot]]
    private let onTap: (AyahNumber, CGPoint) -> Void
}

/// An invisible button that opens the ayah menu for a bookmarked marker.
struct AyahReadingBookmarkButton: View {
    let ayah: AyahNumber
    let slots: [ReadingBookmarkSlot]
    let size: CGSize
    var onPressedChange: (Bool) -> Void = { _ in }
    let action: (CGPoint) -> Void

    var body: some View {
        Button {
            action(CGPoint(x: globalFrame.midX, y: globalFrame.midY))
        } label: {
            Color.clear
                .frame(width: size.width, height: size.height)
                .minimumTouchTarget()
        }
        .buttonStyle(ReadingBookmarkPressReportingStyle(onPressedChange: onPressedChange))
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("ayah-reading-bookmark-\(ayah.sura.suraNumber)-\(ayah.ayah)")
        .onGlobalFrameChanged { globalFrame = $0 }
        // A target removed mid-press, say by a sync, never reports its release.
        .onDisappear { onPressedChange(false) }
    }

    var accessibilityLabel: String {
        slots.accessibilityLabel(prefixedBy: ayah.localizedName)
    }

    @State private var globalFrame: CGRect = .zero
}
#endif
