#if QURAN_SYNC
import NoorFont
import QuranAnnotations
import QuranKit
import QuranLocalization
import SwiftUI
import UIx

@MainActor
public struct ContinueReadingBookmarkRow: View {
    public init(bookmark: PlacedReadingBookmark, action: @escaping () -> Void) {
        self.bookmark = bookmark
        self.action = action
    }

    private let bookmark: PlacedReadingBookmark
    private let action: () -> Void

    public var body: some View {
        Button(action: action) {
            NoorListItem(
                image: .init(.bookmark, color: bookmark.slot.swiftUIColor),
                title: title,
                titleAllowsWrapping: false,
                subtitle: .init(text: subtitle, location: .bottom),
                accessory: .disclosureIndicator
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(BackgroundHighlightingStyle())
        .listRowInsets(EdgeInsets())
        .accessibilityIdentifier("home.readingBookmark.\(bookmark.slot)")
    }

    /// A named bookmark shows its name, and its location moves to the subtitle.
    var title: MultipartText {
        if let name = bookmark.name {
            return .text(name)
        }
        return placementText
    }

    /// Keeps the page number out of the title so long sura names never truncate it.
    var subtitle: MultipartText {
        let timeAgo = bookmark.modifiedOn.timeAgo()
        switch bookmark.placement {
        case .ayah:
            if bookmark.name == nil {
                return .text(timeAgo)
            }
            return "\(placementText) · \(timeAgo)"
        case .page(let page):
            if bookmark.name == nil {
                return "\(page.localizedName) · \(timeAgo)"
            }
            return "\(placementText) · \(page.localizedName) · \(timeAgo)"
        }
    }

    private var placementText: MultipartText {
        switch bookmark.placement {
        case .ayah(let ayah):
            "\(ayah: ayah)"
        case .page(let page):
            "\(suras: page.suras)"
        }
    }

    private var location: String {
        switch bookmark.placement {
        case .ayah(let ayah): ayah.page.localizedName
        case .page(let page): page.startJuz.localizedName
        }
    }
}

// MARK: - Previews

@MainActor
private struct ContinueReadingBookmarkRowPreview: View {
    init(placement: PlacedReadingBookmark.Placement, slot: ReadingBookmarkSlot = .orange, name: String? = nil) {
        bookmark = PlacedReadingBookmark(
            id: "preview", slot: slot, placement: placement,
            modifiedOn: Date(timeIntervalSinceNow: -36000), name: name
        )
        if UIFont(name: "icomoon", size: 20) == nil {
            FontName.registerFonts()
        }
    }

    private let bookmark: PlacedReadingBookmark

    var body: some View {
        Section {
            ContinueReadingBookmarkRow(bookmark: bookmark, action: {})
        }
    }
}

#Preview {
    List {
        ContinueReadingBookmarkRowPreview(placement: .ayah(Quran.hafsMadani1405.suras[0].verses[5]))
            .environment(\.locale, Locale(identifier: "en"))

        ContinueReadingBookmarkRowPreview(placement: .page(Quran.hafsMadani1405.pages[22]), slot: .teal)
            .environment(\.locale, Locale(identifier: "en"))

        ContinueReadingBookmarkRowPreview(placement: .page(Quran.hafsMadani1405.pages[574]), slot: .teal)
            .environment(\.locale, Locale(identifier: "en"))

        ContinueReadingBookmarkRowPreview(placement: .page(Quran.hafsMadani1405.pages[2]), slot: .red, name: "Khatmah")
            .environment(\.locale, Locale(identifier: "en"))

        ContinueReadingBookmarkRowPreview(placement: .ayah(Quran.hafsMadani1405.suras[17].verses[9]), name: "Hifz")
            .environment(\.locale, Locale(identifier: "en"))

        ContinueReadingBookmarkRowPreview(placement: .ayah(Quran.hafsMadani1405.suras[35].verses[57]), slot: .red)
            .environment(\.locale, Locale(identifier: "ar"))
            .environment(\.layoutDirection, .rightToLeft)

        ContinueReadingBookmarkRowPreview(placement: .ayah(Quran.hafsMadani1405.suras[62].verses[0]))
            .environment(\.locale, Locale(identifier: "en"))
            .environment(\.dynamicTypeSize, .accessibility3)
    }
}
#endif
