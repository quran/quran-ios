//
//  TextLengthLimitError+Localization.swift
//
//  Created by Mohamed Afifi on 2026-10-13.
//

import Localization
import QuranAnnotations

extension TextLengthLimitError {
    public var localizedMessage: String {
        switch (field, bound) {
        case (.noteBody, .tooShort):
            lFormat("notes.minimum-length.alert.body", limit)
        case (.noteBody, .tooLong):
            lFormat("notes.maximum-length.alert.body", limit)
        case (.collectionName, .tooShort):
            l("bookmarks.collections.name.empty")
        case (.collectionName, .tooLong):
            lFormat("bookmarks.collections.name.too-long", limit)
        }
    }
}
