#if QURAN_SYNC
//
//  BookmarkCollectionErrors+Presentation.swift
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import Foundation
import Localization
import NoorUI
import QuranAnnotations

/// The error alert shows this message when a collection turns read-only before a rename or delete lands.
extension ReadOnlyCollectionError: @retroactive LocalizedError {
    public var errorDescription: String? {
        l("bookmarks.collections.read-only")
    }
}

#endif
