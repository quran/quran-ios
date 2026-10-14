//
//  Note.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//

import Foundation
import QuranKit

public struct Note: Equatable {
    // MARK: Lifecycle

    #if QURAN_SYNC
    /// A note on Quran.com can cover several ranges, so `verses` need not be consecutive.
    ///
    /// - Precondition: `verses` isn't empty. Every note covers at least one verse, and `startAyah` and `endAyah`
    ///   rely on it; `MobileSyncNoteService` skips a synced note it can't map to verses.
    public init(id: String, text: String, verses: Set<AyahNumber>, modifiedDate: Date) {
        precondition(!verses.isEmpty, "A note needs at least one verse.")
        self.id = id
        self.text = text
        self.verses = verses.sorted()
        verseSet = verses
        self.modifiedDate = modifiedDate
    }
    #else
    public init(verses: Set<AyahNumber>, modifiedDate: Date, text: String?, color: HighlightColor) {
        let sortedVerses = verses.sorted()
        self.verses = sortedVerses[0].array(to: sortedVerses[sortedVerses.count - 1])
        verseSet = Set(self.verses)
        self.modifiedDate = modifiedDate
        self.color = color
        self.text = text
    }
    #endif

    // MARK: Public

    public let modifiedDate: Date
    /// The note's verses in order.
    public let verses: [AyahNumber]

    public var startAyah: AyahNumber {
        verses[0]
    }

    public var endAyah: AyahNumber {
        verses[verses.count - 1]
    }

    public func intersects(verses: [AyahNumber]) -> Bool {
        verses.contains { verseSet.contains($0) }
    }

    #if QURAN_SYNC
    public let id: String
    public let text: String
    #else
    public let color: HighlightColor
    public let text: String?
    #endif

    // MARK: Private

    private let verseSet: Set<AyahNumber>
}

#if QURAN_SYNC
extension Note: Identifiable, Sendable {}
#endif
