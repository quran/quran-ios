//
//  ImageDecorations.swift
//

import QuranGeometry
import QuranKit
import SwiftUI

public struct ImageDecorations {
    public var suraHeaders: [SuraHeaderLocation]
    public var ayahNumbers: [AyahNumberLocation]
    /// An ayah marker's side as a fraction of the image width.
    public var ayahNumberWidthRatio: CGFloat = 0.06
    public var drawsAyahNumbersAndSuraHeaders: Bool
    public var chromeStyle: QuranPageChromeStyle
    public var wordFrames: WordFrameCollection
    /// The page's text extent in image coordinates, for the header to line up with.
    public var textColumn: ClosedRange<CGFloat>?
    public var verseHighlights: [AyahNumber: Color]
    public var wordHighlight: Word?
    public var undimmedVerses: Set<AyahNumber>?

    public init(
        suraHeaders: [SuraHeaderLocation],
        ayahNumbers: [AyahNumberLocation],
        drawsAyahNumbersAndSuraHeaders: Bool,
        chromeStyle: QuranPageChromeStyle = .green,
        wordFrames: WordFrameCollection,
        textColumn: ClosedRange<CGFloat>? = nil,
        verseHighlights: [AyahNumber: Color] = [:],
        wordHighlight: Word? = nil,
        undimmedVerses: Set<AyahNumber>? = nil
    ) {
        self.suraHeaders = suraHeaders
        self.ayahNumbers = ayahNumbers
        self.drawsAyahNumbersAndSuraHeaders = drawsAyahNumbersAndSuraHeaders
        self.chromeStyle = chromeStyle
        self.wordFrames = wordFrames
        self.textColumn = textColumn
        self.verseHighlights = verseHighlights
        self.wordHighlight = wordHighlight
        self.undimmedVerses = undimmedVerses
    }
}
