//
//  WordFrameCollection.swift
//
//
//  Created by Mohamed Afifi on 2021-12-26.
//

import QuranKit

public struct WordFrameCollection: Equatable {
    public var lines: [[WordFrame]]

    public init(lines: [[WordFrame]]) {
        self.lines = lines
    }

    public func wordFramesForVerse(_ verse: AyahNumber) -> [WordFrame] {
        lines
            .flatMap { $0 }
            .filter { $0.word.verse == verse }
    }

    public func wordFrameForWord(_ word: Word) -> WordFrame? {
        let frames = wordFramesForVerse(word.verse)
        return frames.first(where: { $0.word == word })
    }
}
