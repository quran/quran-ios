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
                image: .init(Image(uiImage: ReadingBookmarkPin.image(style: .filled)), color: bookmark.slot.swiftUIColor),
                title: title,
                titleAllowsWrapping: false,
                subtitle: .init(text: "\(bookmark.modifiedOn.timeAgo())", location: .bottom),
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

    private var title: MultipartText {
        switch bookmark.placement {
        case .ayah(let ayah):
            "\(ayah: ayah, nameStyle: .compact)"
        case .page(let page):
            "\(sura: bookmark.sura, nameStyle: .compact) · \(page.localizedName)"
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
    init(placement: PlacedReadingBookmark.Placement, slot: ReadingBookmarkSlot = .teal) {
        bookmark = PlacedReadingBookmark(
            id: "preview", slot: slot, placement: placement,
            modifiedOn: Date(timeIntervalSinceNow: -36000)
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

        ContinueReadingBookmarkRowPreview(placement: .page(Quran.hafsMadani1405.pages[22]), slot: .coral)
            .environment(\.locale, Locale(identifier: "en"))

        ContinueReadingBookmarkRowPreview(placement: .ayah(Quran.hafsMadani1405.suras[35].verses[57]), slot: .indigo)
            .environment(\.locale, Locale(identifier: "ar"))
            .environment(\.layoutDirection, .rightToLeft)

        ContinueReadingBookmarkRowPreview(placement: .ayah(Quran.hafsMadani1405.suras[62].verses[0]))
            .environment(\.locale, Locale(identifier: "en"))
            .environment(\.dynamicTypeSize, .accessibility3)
    }
}
#endif
