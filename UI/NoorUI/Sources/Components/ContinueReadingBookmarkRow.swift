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

    /// Every bookmark shows its page once: a page bookmark's location already names it.
    var subtitle: MultipartText {
        let timeAgo = bookmark.modifiedOn.timeAgo()
        switch (bookmark.placement, bookmark.name) {
        case (.page, nil):
            return .text(timeAgo)
        case (.page, _):
            return "\(placementText) · \(timeAgo)"
        case (.ayah(let ayah), nil):
            return "\(ayah.page.localizedName) · \(timeAgo)"
        case (.ayah(let ayah), _):
            return "\(placementText) · \(ayah.page.localizedName) · \(timeAgo)"
        }
    }

    /// Names only the page's first sura, like the reader's page header and the Juz' list.
    private var placementText: MultipartText {
        switch bookmark.placement {
        case .ayah(let ayah):
            "\(ayah: ayah)"
        case .page(let page):
            "\(page: page)"
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

        ContinueReadingBookmarkRowPreview(placement: .page(Quran.hafsMadani1405.pages[22]), slot: .teal)
            .environment(\.locale, Locale(identifier: "ar"))
            .environment(\.layoutDirection, .rightToLeft)

        ContinueReadingBookmarkRowPreview(placement: .ayah(Quran.hafsMadani1405.suras[62].verses[0]))
            .environment(\.locale, Locale(identifier: "en"))
            .environment(\.dynamicTypeSize, .accessibility3)

        ContinueReadingBookmarkRowPreview(placement: .page(Quran.hafsMadani1405.pages[548]), slot: .teal)
            .environment(\.locale, Locale(identifier: "en"))
            .environment(\.dynamicTypeSize, .accessibility3)
    }
}
#endif
