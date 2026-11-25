//
//  UIBarButtonItem+ReaderBookmark.swift
//
//
//  Created by Mohamed Afifi on 2026-11-24.
//

import Localization
import NoorUI
#if QURAN_SYNC
import QuranAnnotations
#endif
import UIKit

/// The reader's bookmark button, in its own bar and in the rail.
extension UIBarButtonItem {
    #if QURAN_SYNC
    func configureReadingBookmark(_ bookmark: PlacedReadingBookmark?, defaultTintColor: UIColor?) {
        image = ReadingBookmarkIcon.image(style: bookmark == nil ? .outline : .filled, badge: .ellipsis)
        tintColor = bookmark?.slot.color ?? defaultTintColor
        accessibilityValue = bookmark?.displayName
    }
    #else
    func configurePageBookmark(isBookmarked: Bool, defaultTintColor: UIColor?) {
        image = (isBookmarked ? NoorSystemImage.bookmark : .bookmarkOutline).uiImage
        accessibilityLabel = l(isBookmarked ? "bookmarks.page.remove" : "bookmarks.page.add")
        tintColor = isBookmarked ? .systemRed : defaultTintColor
    }
    #endif
}
