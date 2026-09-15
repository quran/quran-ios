#if QURAN_SYNC
import QuranAnnotations
import SwiftUI

struct AyahAnnotationIcon: View {
    let annotation: AyahAnnotation
    let size: CGFloat

    var body: some View {
        Group {
            switch annotation {
            case .readingBookmark(let bookmark):
                Image(uiImage: ReadingBookmarkPin.image(style: .filled))
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(bookmark.swiftUIColor)
            case .collection:
                NoorSystemImage.bookmark.image
                    .themedSecondaryForeground()
            case .note:
                NoorSystemImage.note.image
                    .themedSecondaryForeground()
            }
        }
        .symbolRenderingMode(.monochrome)
        .frame(width: size, height: size)
        .accessibilityLabel(annotation.accessibilityLabel)
    }
}
#endif
