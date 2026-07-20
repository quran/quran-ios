#if QURAN_SYNC
//
//  ReadingBookmarkAction.swift
//

import QuranAnnotations
import QuranKit

enum ReadingBookmarkAction: Equatable {
    case set(
        location: ReadingPositionBookmark.Location,
        replacing: ReadingPositionBookmark?
    )
    case remove(ReadingPositionBookmark)

    static func page(
        visiblePages: [Page],
        bookmark: ReadingPositionBookmark?
    ) -> ReadingBookmarkAction? {
        guard let targetPage = visiblePages.min() else {
            return nil
        }
        if let bookmark,
           case .page(let page) = bookmark.location,
           page == targetPage
        {
            return .remove(bookmark)
        }
        return .set(location: .page(targetPage), replacing: bookmark)
    }
}
#endif
