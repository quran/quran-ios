#if QURAN_SYNC
import Localization
import QuranAnnotations

extension Set<AyahAnnotation> {
    var ordered: [AyahAnnotation] {
        var result: [AyahAnnotation] = []
        for slot in ReadingBookmarkSlot.allCases {
            result += filter {
                if case .readingBookmark(let bookmark) = $0 {
                    return bookmark == slot
                }
                return false
            }
        }
        result += [.collection, .note]
        return result.filter(contains)
    }
}

extension AyahAnnotation {
    var accessibilityLabel: String {
        switch self {
        case .readingBookmark(let bookmark):
            "\(l("ayah.menu.reading-bookmark.title")), \(bookmark.displayName)"
        case .collection:
            l("bookmarks.collections")
        case .note:
            l("tab.notes")
        }
    }
}
#endif
