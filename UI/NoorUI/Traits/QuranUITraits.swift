//
//  QuranUITraits.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/29/21.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import Foundation
import QuranAnnotations
import QuranKit
import QuranText

public struct QuranUITraits: Equatable {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var shareHighlights: [AyahNumber] = []
    public var searchHighlights: [AyahNumber] = []
    public var readingHighlights: [AyahNumber] = []
    public var notesHighlights: [AyahNumber: Note] = [:]

    public var highlightedWord: Word?

    public var translationFontSize: FontSize = .xSmall
    public var arabicFontSize: FontSize = .xSmall

    public var versesHighlights: VerseHighlights {
        [
            .share: shareHighlights.map { (.share, $0) },
            .search: searchHighlights.map { (.search, $0) },
            .reading: readingHighlights.map { (.reading, $0) },
            .note: notesHighlights.map { (.note($0.value.color), $0.key) },
        ]
    }

    public mutating func removeHighlights() {
        shareHighlights = []
        searchHighlights = []
        readingHighlights = []
        notesHighlights = [:]
    }
}
