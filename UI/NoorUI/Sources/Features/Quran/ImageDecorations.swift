//
//  ImageDecorations.swift
//

import QuranGeometry
import SwiftUI

public struct ImageDecorations {
    public var suraHeaders: [SuraHeaderLocation]
    public var ayahNumbers: [AyahNumberLocation]
    public var drawsAyahNumbersAndSuraHeaders: Bool
    public var wordFrames: WordFrameCollection
    public var highlights: [WordFrame: Color]

    public init(
        suraHeaders: [SuraHeaderLocation],
        ayahNumbers: [AyahNumberLocation],
        drawsAyahNumbersAndSuraHeaders: Bool,
        wordFrames: WordFrameCollection,
        highlights: [WordFrame: Color]
    ) {
        self.suraHeaders = suraHeaders
        self.ayahNumbers = ayahNumbers
        self.drawsAyahNumbersAndSuraHeaders = drawsAyahNumbersAndSuraHeaders
        self.wordFrames = wordFrames
        self.highlights = highlights
    }
}
