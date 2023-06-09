//
//  WordFrameCollection.swift
//
//
//  Created by Mohamed Afifi on 2021-12-26.
//

import QuranKit

public struct WordFrameCollection: Equatable {
    public let frames: [AyahNumber: [WordFrame]]

    public init(frames: [AyahNumber: [WordFrame]]) {
        self.frames = frames
    }

    public func wordFramesForVerse(_ verse: AyahNumber) -> [WordFrame]? {
        frames[verse]
    }

    public func wordFrameForWord(_ word: Word) -> WordFrame? {
        if let frames = wordFramesForVerse(word.verse) {
            return frames.first(where: { $0.word == word })
        }
        return nil
    }
}
