#if QURAN_SYNC
import Localization
import NoorUI

extension AyahBookmarkCollection {
    var displayName: String {
        switch kind {
        case .defaultBookmarks:
            l("bookmarks.collections.favorites")
        case .oldPageBookmarks:
            l("bookmarks.old-page-bookmarks")
        case .colored(let color):
            color.localizedName
        case .user:
            collection.name
        }
    }

    var displayImage: NoorSystemImage {
        switch kind {
        case .defaultBookmarks:
            .starFilled
        case .oldPageBookmarks:
            .book
        case .colored:
            .bookmark
        case .user:
            .folder
        }
    }
}
#endif
