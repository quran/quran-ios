#if QURAN_SYNC
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

    var displayImageColor: Color {
        switch kind {
        case .defaultBookmarks:
            Color(uiColor: .systemYellow)
        case .oldPageBookmarks:
            .secondaryLabel
        case .colored, .user:
            .appIdentity
        }
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
