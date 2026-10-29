#if QURAN_SYNC
//
//  AyahReadingBookmarkUnderlines.swift
//

import QuranAnnotations
import QuranKit
import SwiftUI
import UIx

/// Reading bookmark underlines under bookmarked ayah markers.
///
/// Draw it behind the page image or lines so it never covers Quran text,
/// and put `AyahReadingBookmarkTargets` above the page to make it tappable.
public struct AyahReadingBookmarkUnderlines: View {
    // MARK: Lifecycle

    public init(markers: [AyahMarkerPlacement], bookmarks: [AyahNumber: [ReadingBookmarkSlot]]) {
        self.markers = markers
        self.bookmarks = bookmarks
    }

    // MARK: Public

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(markers.bookmarked(by: bookmarks), id: \.ayah) { placement in
                let slots = bookmarks[placement.ayah, default: []]
                let layout = AyahReadingBookmarkUnderlineLayout(markerFrame: placement.frame, count: slots.count)
                ForEach(Array(zip(slots, layout.underlineFrames)), id: \.0) { slot, frame in
                    Capsule()
                        .fill(slot.swiftUIColor)
                        .placed(in: frame)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.layoutDirection, .leftToRight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Private

    private let markers: [AyahMarkerPlacement]
    private let bookmarks: [AyahNumber: [ReadingBookmarkSlot]]
}

extension [AyahMarkerPlacement] {
    func bookmarked(by bookmarks: [AyahNumber: [ReadingBookmarkSlot]]) -> [AyahMarkerPlacement] {
        filter { bookmarks[$0.ayah]?.isEmpty == false }
    }
}

private struct AyahReadingBookmarkUnderlinesPreview: View {
    var body: some View {
        VStack {
            Text("Dashed rectangles show marker frames; dotted ones show tap targets.")
                .font(.caption)

            ZStack(alignment: .topLeading) {
                AyahReadingBookmarkUnderlines(markers: markers, bookmarks: bookmarks)

                ForEach(markers, id: \.ayah) { placement in
                    AyahNumberView(number: placement.ayah.ayah)
                        .placed(in: placement.frame)
                    Rectangle()
                        .stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .placed(in: placement.frame)
                    Rectangle()
                        .stroke(.tertiary, style: StrokeStyle(lineWidth: 1, dash: [1, 2]))
                        .placed(in: AyahReadingBookmarkUnderlineLayout(
                            markerFrame: placement.frame,
                            count: bookmarks[placement.ayah, default: []].count
                        ).hitFrame)
                }
            }
            .frame(width: 300, height: 260)
            .allowsHitTesting(false)
            .overlay {
                AyahReadingBookmarkTargets(markers: markers, bookmarks: bookmarks) { ayah, _ in
                    tappedAyah = ayah
                }
            }

            Text(tappedAyah.map { "Tapped ayah \($0.ayah)" } ?? "Tap a bookmarked marker")
                .font(.footnote)
        }
        .padding()
        .themedBackground()
        .environment(\.themeStyle, .paper)
    }

    @State private var tappedAyah: AyahNumber?
    private let ayahs = Array(Quran.hafsMadani1405.suras[1].verses.prefix(4))

    private var markers: [AyahMarkerPlacement] {
        [
            AyahMarkerPlacement(ayah: ayahs[0], frame: CGRect(x: 30, y: 20, width: 24, height: 24)),
            AyahMarkerPlacement(ayah: ayahs[1], frame: CGRect(x: 140, y: 20, width: 40, height: 40)),
            AyahMarkerPlacement(ayah: ayahs[2], frame: CGRect(x: 40, y: 130, width: 60, height: 60)),
            AyahMarkerPlacement(ayah: ayahs[3], frame: CGRect(x: 200, y: 130, width: 40, height: 40)),
        ]
    }

    private var bookmarks: [AyahNumber: [ReadingBookmarkSlot]] {
        [
            ayahs[0]: [.teal],
            ayahs[1]: [.orange],
            ayahs[2]: ReadingBookmarkSlot.allCases,
        ]
    }
}

#Preview("Reading bookmark underlines") {
    AyahReadingBookmarkUnderlinesPreview()
}
#endif
