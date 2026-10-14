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

extension DuplicateCollectionNameError {
    var localizedMessage: String {
        lFormat("bookmarks.collections.name.duplicate", name)
    }
}

/// The error alert shows this message when a collection turns read-only before a rename or delete lands.
extension ReadOnlyCollectionError: @retroactive LocalizedError {
    public var errorDescription: String? {
        l("bookmarks.collections.read-only")
    }
}

extension CollectionNameError {
    var localizedMessage: String {
        switch self {
        case .textLength(let error):
            error.localizedMessage
        case .duplicate(let error):
            error.localizedMessage
        }
    }
}
#endif
