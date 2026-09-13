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
    public var highlightVerses: [AyahNumber: HighlightColor] = [:]
    public var noteVerses: Set<AyahNumber> = []
    #if QURAN_SYNC
    public var collectionVerses: Set<AyahNumber> = []
    public var readingBookmarks: [PlacedReadingBookmark] = []
    #endif

    public var pointedWord: Word?
}

extension QuranHighlights {
    #if QURAN_SYNC
    public var annotationsByVerse: [AyahNumber: Set<AyahAnnotation>] {
        var annotations: [AyahNumber: Set<AyahAnnotation>] = [:]

        for ayah in noteVerses {
            annotations[ayah, default: []].insert(.note)
        }
        for ayah in collectionVerses {
            annotations[ayah, default: []].insert(.collection)
        }
        for bookmark in readingBookmarks {
            guard case .ayah(let ayah) = bookmark.placement else {
                continue
            }
            annotations[ayah, default: []].insert(.readingBookmark(bookmark.slot))
        }
        return annotations
    }
    #endif

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
