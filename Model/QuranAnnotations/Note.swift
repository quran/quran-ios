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
    public init(id: String, note: String, startAyah: AyahNumber, endAyah: AyahNumber, modifiedDate: Date) {
        self.id = id
        self.note = note
        if startAyah <= endAyah {
            self.startAyah = startAyah
            self.endAyah = endAyah
        } else {
            self.startAyah = endAyah
            self.endAyah = startAyah
        }
        self.modifiedDate = modifiedDate
    }
    #else
    public init(verses: Set<AyahNumber>, modifiedDate: Date, note: String?, color: HighlightColor) {
        let sortedVerses = verses.sorted()
        startAyah = sortedVerses[0]
        endAyah = sortedVerses[sortedVerses.count - 1]
        self.modifiedDate = modifiedDate
        self.color = color
        self.note = note
    }
    #endif

    // MARK: Public

    public let modifiedDate: Date
    public let startAyah: AyahNumber
    public let endAyah: AyahNumber

    public func intersects(verses: [AyahNumber]) -> Bool {
        return verses.contains { ayah in startAyah <= ayah && ayah <= endAyah }
    }

    #if QURAN_SYNC
    public let id: String
    public let note: String
    #else
    public let color: HighlightColor
    public let note: String?
    #endif

    public var verses: [AyahNumber] {
        startAyah.array(to: endAyah)
    }
}

#if QURAN_SYNC
extension Note: Identifiable, Sendable {}
#endif
