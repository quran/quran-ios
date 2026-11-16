#if QURAN_SYNC
import QuranAnnotations
import SwiftUI

/// An indicator's SF Symbol, sized by the surrounding font so every indicator matches.
struct AyahIndicatorIcon: View {
    let indicator: AyahIndicator

    var body: some View {
        Group {
            switch indicator {
            case .readingBookmark(let bookmark):
                NoorSystemImage.bookmark.image
                    .foregroundStyle(bookmark.swiftUIColor)
            case .collection:
                NoorSystemImage.starFilled.image
                    .themedSecondaryForeground()
            case .note:
                NoorSystemImage.notes.image
                    .themedSecondaryForeground()
            }
        }
        .symbolRenderingMode(.monochrome)
        .accessibilityLabel(indicator.accessibilityLabel)
    }
}
#endif
