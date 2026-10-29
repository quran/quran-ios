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
    #if QURAN_SYNC
    public var collectionVerses: Set<AyahNumber> = []
    public var readingBookmarks: [PlacedReadingBookmark] = []
    /// Which indicators `indicators(for:)` and the reading bookmark accessors expose.
    public var indicatorVisibility = AyahIndicatorVisibility.all
    #endif

    public var pointedWord: Word?
}

extension VerseOverlays {
    /// Filters overlays for rendering one page while preserving indicator visibility.
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
    public func indicators(for verse: AyahNumber) -> Set<AyahIndicator> {
        var indicators: Set<AyahIndicator> = []
        if indicatorVisibility.showsNotesAndCollections {
            if notedVerses.contains(verse) {
                indicators.insert(.note)
            }
            if collectionVerses.contains(verse) {
                indicators.insert(.collection)
            }
        }
        if indicatorVisibility.showsReadingBookmarks {
            for bookmark in readingBookmarks where bookmark.isAt(verse) {
                indicators.insert(.readingBookmark(bookmark.slot))
            }
        }
        return indicators
    }

    /// The reading bookmark slots on each bookmarked ayah, in `ReadingBookmarkSlot.allCases` order.
    public var readingBookmarkSlotsByVerse: [AyahNumber: [ReadingBookmarkSlot]] {
        guard indicatorVisibility.showsReadingBookmarks else { return [:] }
        var slotsByVerse: [AyahNumber: [ReadingBookmarkSlot]] = [:]
        for bookmark in readingBookmarks {
            if case .ayah(let ayah) = bookmark.placement {
                slotsByVerse[ayah, default: []].append(bookmark.slot)
            }
        }
        return slotsByVerse.mapValues(Self.ordered)
    }

    /// The reading bookmark slots placed on `page` itself, in `ReadingBookmarkSlot.allCases` order.
    public func pageReadingBookmarkSlots(on page: Page) -> [ReadingBookmarkSlot] {
        guard indicatorVisibility.showsReadingBookmarks else { return [] }
        return Self.ordered(readingBookmarks.compactMap { bookmark in
            bookmark.placement == .page(page) ? bookmark.slot : nil
        })
    }

    private static func ordered(_ slots: [ReadingBookmarkSlot]) -> [ReadingBookmarkSlot] {
        ReadingBookmarkSlot.allCases.filter(slots.contains)
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
