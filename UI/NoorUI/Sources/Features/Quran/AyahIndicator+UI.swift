#if QURAN_SYNC
import Localization
import QuranAnnotations

extension Set<AyahIndicator> {
    var ordered: [AyahIndicator] {
        var result: [AyahIndicator] = []
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

extension Set<AyahIndicator> {
    /// What an ayah marker draws: every reading bookmark, stacked. Without one, a single indicator,
    /// a note before a collection.
    var markerIndicators: [AyahIndicator] {
        let bookmarks = ordered.filter {
            if case .readingBookmark = $0 {
                true
            } else {
                false
            }
        }
        if !bookmarks.isEmpty {
            return bookmarks
        }
        if contains(.note) {
            return [.note]
        }
        return contains(.collection) ? [.collection] : []
    }
}

extension AyahIndicator {
    var accessibilityLabel: String {
        switch self {
        case .readingBookmark(let bookmark):
            lFormat("ayah.indicator.reading-bookmark", l("ayah.menu.reading-bookmark.title"), bookmark.displayName)
        case .collection:
            l("bookmarks.collections")
        case .note:
            l("tab.notes")
        }
    }
}
#endif
