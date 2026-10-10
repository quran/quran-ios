#if QURAN_SYNC
import QuranAnnotations
import SwiftUI

/// An annotation's SF Symbol, sized by the surrounding font so every annotation matches.
struct AyahAnnotationIcon: View {
    let annotation: AyahAnnotation

    var body: some View {
        Group {
            switch annotation {
            case .readingBookmark(let bookmark):
                NoorSystemImage.bookmark.image
                    .foregroundStyle(bookmark.swiftUIColor)
            case .collection:
                NoorSystemImage.folder.image
                    .themedSecondaryForeground()
            case .note:
                NoorSystemImage.note.image
                    .themedSecondaryForeground()
            }
        }
        .symbolRenderingMode(.monochrome)
        .accessibilityLabel(annotation.accessibilityLabel)
    }
}
#endif
