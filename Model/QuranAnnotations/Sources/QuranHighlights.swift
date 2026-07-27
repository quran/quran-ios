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
    public var navigationVerse: AyahNumber?
    #if QURAN_SYNC
    public var highlightVerses: [AyahNumber: HighlightColor] = [:]
    #else
    public var noteVerses: [AyahNumber: Note] = [:]
    #endif

    public var pointedWord: Word?
}

extension QuranHighlights {
    public func needsScrolling(comparingTo oldValue: Self) -> Bool {
        if oldValue.readingVerses != readingVerses {
            return true
        }
        if oldValue.navigationVerse != navigationVerse {
            return true
        }
        return false
    }

    public func firstScrollingVerse() -> AyahNumber? {
        if let firstReadingVerse = readingVerses.first {
            return firstReadingVerse
        }
        return navigationVerse
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
