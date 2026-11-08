#if QURAN_SYNC
import AnnotationsService
import Localization
import NoorUI
import QuranAnnotations
import SwiftUI

extension AyahBookmarkCollection {
    var displayName: String {
        switch kind {
        case .defaultBookmarks:
            l("bookmarks.collections.favorites")
        case .oldPageBookmarks:
            l("bookmarks.old-page-bookmarks")
        case .user:
            name
        }
    }

    /// Favorites and user collections share the star, the app's icon for a collection.
    var displayImage: NoorSystemImage {
        switch kind {
        case .defaultBookmarks, .user:
            .starFilled
        case .oldPageBookmarks:
            .book
        }
    }

    /// Explains where the imported ayahs came from.
    var ayahsHeader: String? {
        guard kind == .oldPageBookmarks, !bookmarks.isEmpty else {
            return nil
        }
        return l("bookmarks.old-page-bookmarks.explanation")
    }

    var displayImageColor: Color {
        .secondaryLabel
    }

    /// Read-only collections can't be deleted, so they offer to remove their ayahs instead.
    var canRemoveAllAyahs: Bool {
        isReadOnly && !bookmarks.isEmpty
    }
}

extension HighlightColor {
    static var alphabeticallySortedColors: [Self] {
        allCases.sorted {
            $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending
        }
    }
}
#endif
