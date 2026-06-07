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
        public init(verses: Set<AyahNumber>, modifiedDate: Date, note: String) {
            self.verses = verses
            self.modifiedDate = modifiedDate
            self.note = note
        }
    #else
        public init(verses: Set<AyahNumber>, modifiedDate: Date, note: String?, color: HighlightColor) {
            self.verses = verses
            self.modifiedDate = modifiedDate
            self.color = color
            self.note = note
        }
    #endif

    // MARK: Public

    public let verses: Set<AyahNumber>
    public let modifiedDate: Date
    #if QURAN_SYNC
        public let note: String
    #else
        public let color: HighlightColor
        public let note: String?
    #endif

    public var firstVerse: AyahNumber {
        verses.sorted()[0]
    }
}
