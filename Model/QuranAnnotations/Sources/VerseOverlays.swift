//
//  VerseOverlays.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
//

import QuranKit
import QuranText

public struct VerseOverlays: Equatable {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var playingVerses: [AyahNumber] = []
    public var selectedVerses: [AyahNumber] = []
    public var navigationTarget: AyahNumber?
    public var colorHighlights: [AyahNumber: HighlightColor] = [:]
    public var notedVerses: Set<AyahNumber> = []
    public var annotationsHidden = false
    #if QURAN_SYNC
    public var collectionVerses: Set<AyahNumber> = []
    public var readingBookmarks: [PlacedReadingBookmark] = []
    /// The reader's indicator preference, applied by `annotationTypes(for:)` and `annotationsByVerse`.
    public var ayahIndicators = AyahIndicators.all
    #endif

    public var pointedWord: Word?
}

extension VerseOverlays {
    /// Filters overlays for rendering one page while preserving annotation visibility.
    public func restricted(to page: Page) -> Self {
        var overlays = self
        overlays.playingVerses = playingVerses.filter { $0.page == page }
        overlays.selectedVerses = selectedVerses.filter { $0.page == page }
        overlays.navigationTarget = navigationTarget.flatMap { $0.page == page ? $0 : nil }
        overlays.colorHighlights = colorHighlights.filter { $0.key.page == page }
        overlays.notedVerses = notedVerses.filter { $0.page == page }
        overlays.pointedWord = pointedWord.flatMap { $0.verse.page == page ? $0 : nil }
        #if QURAN_SYNC
        overlays.collectionVerses = collectionVerses.filter { $0.page == page }
        overlays.readingBookmarks = readingBookmarks.filter { bookmark in
            switch bookmark.placement {
            case .ayah(let ayah): ayah.page == page
            case .page(let bookmarkedPage): bookmarkedPage == page
            }
        }
        #endif
        return overlays
    }

    #if QURAN_SYNC
    public func annotationTypes(for verse: AyahNumber) -> Set<AyahAnnotation> {
        var annotations: Set<AyahAnnotation> = []
        if ayahIndicators.showsNotesAndCollections {
            if notedVerses.contains(verse) {
                annotations.insert(.note)
            }
            if collectionVerses.contains(verse) {
                annotations.insert(.collection)
            }
        }
        if ayahIndicators.showsReadingBookmarks {
            for bookmark in readingBookmarks where bookmark.isAt(verse) {
                annotations.insert(.readingBookmark(bookmark.slot))
            }
        }
        return annotations
    }

    public var annotationsByVerse: [AyahNumber: Set<AyahAnnotation>] {
        var verses: Set<AyahNumber> = []
        if ayahIndicators.showsNotesAndCollections {
            verses.formUnion(notedVerses)
            verses.formUnion(collectionVerses)
        }
        if ayahIndicators.showsReadingBookmarks {
            verses.formUnion(readingBookmarks.compactMap { bookmark -> AyahNumber? in
                guard case .ayah(let ayah) = bookmark.placement else { return nil }
                return ayah
            })
        }
        return Dictionary(uniqueKeysWithValues: verses.map { ($0, annotationTypes(for: $0)) })
    }
    #endif

    public func needsScrolling(comparingTo oldValue: Self) -> Bool {
        if oldValue.playingVerses != playingVerses {
            return true
        }
        if oldValue.navigationTarget != navigationTarget {
            return true
        }
        return false
    }

    public func firstScrollingVerse() -> AyahNumber? {
        if let firstPlayingVerse = playingVerses.first {
            return firstPlayingVerse
        }
        return navigationTarget
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

        return verseToScrollToIfChanged(\.selectedVerses) ?? verseToScrollToIfChanged(\.playingVerses)
    }
}
