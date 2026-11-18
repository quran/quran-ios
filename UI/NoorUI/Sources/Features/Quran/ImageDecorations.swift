//
//  ImageDecorations.swift
//

import QuranGeometry
import QuranKit
import SwiftUI

public struct ImageDecorations {
    public var suraHeaders: [SuraHeaderLocation]
    public var ayahNumbers: [AyahNumberLocation]
    public var ayahNumberWidthRatio: CGFloat
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
        ayahNumberWidthRatio: CGFloat = AyahMarkerWidthRatio.imagePage,
        drawsAyahNumbersAndSuraHeaders: Bool,
        chromeStyle: QuranPageChromeStyle,
        wordFrames: WordFrameCollection,
        textColumn: ClosedRange<CGFloat>? = nil,
        verseHighlights: [AyahNumber: Color] = [:],
        wordHighlight: Word? = nil,
        undimmedVerses: Set<AyahNumber>? = nil
    ) {
        self.suraHeaders = suraHeaders
        self.ayahNumbers = ayahNumbers
        self.ayahNumberWidthRatio = ayahNumberWidthRatio
        self.drawsAyahNumbersAndSuraHeaders = drawsAyahNumbersAndSuraHeaders
        self.chromeStyle = chromeStyle
        self.wordFrames = wordFrames
        self.textColumn = textColumn
        self.verseHighlights = verseHighlights
        self.wordHighlight = wordHighlight
        self.undimmedVerses = undimmedVerses
    }
}
