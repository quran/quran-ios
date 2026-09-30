//
//  ImageDecorations.swift
//

import QuranGeometry
import QuranKit
import SwiftUI

public struct ImageDecorations {
    public var suraHeaders: [SuraHeaderLocation]
    public var ayahNumbers: [AyahNumberLocation]
    public var drawsAyahNumbersAndSuraHeaders: Bool
    public var wordFrames: WordFrameCollection
    public var verseHighlights: [AyahNumber: Color]
    public var wordHighlight: Word?

    public init(
        suraHeaders: [SuraHeaderLocation],
        ayahNumbers: [AyahNumberLocation],
        drawsAyahNumbersAndSuraHeaders: Bool,
        wordFrames: WordFrameCollection,
        verseHighlights: [AyahNumber: Color] = [:],
        wordHighlight: Word? = nil
    ) {
        self.suraHeaders = suraHeaders
        self.ayahNumbers = ayahNumbers
        self.drawsAyahNumbersAndSuraHeaders = drawsAyahNumbersAndSuraHeaders
        self.wordFrames = wordFrames
        self.verseHighlights = verseHighlights
        self.wordHighlight = wordHighlight
    }
}
