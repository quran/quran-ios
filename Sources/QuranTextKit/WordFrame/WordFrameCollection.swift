//
//  WordFrameCollection.swift
//
//
//  Created by Mohamed Afifi on 2021-12-26.
//

import CoreGraphics
import QuranKit

public struct WordFrameCollection: Equatable {
    let frames: [AyahNumber: [WordFrame]]

    public func wordFramesForVerse(_ verse: AyahNumber) -> [WordFrame]? {
        frames[verse]
    }

    public func wordFrameForWord(_ word: Word) -> WordFrame? {
        if let frames = wordFramesForVerse(word.verse) {
            return frames.first(where: { $0.word == word })
        }
        return nil
    }

    public func wordAtLocation(_ location: CGPoint, imageScale: WordFrameScale) -> Word? {
        let flattenFrames = frames.values.flatMap { $0 }
        for frame in flattenFrames {
            let rectangle = frame.rect.scaled(by: imageScale)
            if rectangle.contains(location) {
                return frame.word
            }
        }
        return nil
    }
}
