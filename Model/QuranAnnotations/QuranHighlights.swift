//
//  QuranHighlights.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
//

import QuranKit

public struct QuranHighlights: Equatable {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var readingVerses: [AyahNumber] = []
    public var shareVerses: [AyahNumber] = []
    public var searchVerses: [AyahNumber] = []
    public var noteVerses: [AyahNumber: Note] = [:]

    public var pointedWord: Word?
}

extension QuranHighlights {
    public func needsScrolling(comparingTo oldValue: Self) -> Bool {
        // Check readingHighlights & searchHighlights
        if oldValue.readingVerses != readingVerses {
            return true
        }
        if oldValue.searchVerses != searchVerses {
            return true
        }
        return false
    }

    public func firstScrollingVerse() -> AyahNumber? {
        if let firstReadingVerse = readingVerses.first {
            return firstReadingVerse
        }
        return searchVerses.first
    }

    public func verseToScrollTo(comparingTo oldValue: Self) -> AyahNumber? {
        func verseToScrollToIfChanged(_ keyPath: KeyPath<Self, [AyahNumber]>) -> AyahNumber? {
            let ayahToScrollTo = self[keyPath: keyPath].last
            if self[keyPath: keyPath] != oldValue[keyPath: keyPath] {
                if let ayah = ayahToScrollTo {
                    return ayah
                }
            }
            return nil
        }

        return verseToScrollToIfChanged(\.shareVerses) ?? verseToScrollToIfChanged(\.readingVerses)
    }
}
