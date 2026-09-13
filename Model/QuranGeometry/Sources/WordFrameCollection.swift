//
//  WordFrameCollection.swift
//
//
//  Created by Mohamed Afifi on 2021-12-26.
//

import CoreGraphics
import QuranKit

public struct WordFrameCollection: Equatable {
    public var frames: [WordFrame]

    public init(frames: [WordFrame]) {
        self.frames = frames
    }

    /// The earliest available frame for each verse, in verse order.
    public var verseStartFrames: [WordFrame] {
        Dictionary(grouping: frames, by: \.word.verse)
            .sorted { $0.key < $1.key }
            .compactMap { _, frames in
                frames.min(by: Self.precedesInVerse)
            }
    }

    /// Supports verses continuing from a previous page.
    public func verseStartFrame(for verse: AyahNumber) -> WordFrame? {
        frames.lazy
            .filter { $0.word.verse == verse }
            .min(by: Self.precedesInVerse)
    }

    public func wordFramesForVerse(_ verse: AyahNumber) -> [WordFrame] {
        frames.filter { $0.word.verse == verse }
    }

    public func wordFrameForWord(_ word: Word) -> WordFrame? {
        frames.first(where: { $0.word == word })
    }

    public func wordAtLocation(_ location: CGPoint, imageScale: WordFrameScale) -> Word? {
        for frame in frames {
            let rectangle = frame.rect.scaled(by: imageScale)
            if rectangle.contains(location) {
                return frame.word
            }
        }
        return nil
    }

    private static func precedesInVerse(_ lhs: WordFrame, _ rhs: WordFrame) -> Bool {
        if lhs.word.wordNumber != rhs.word.wordNumber {
            return lhs.word.wordNumber < rhs.word.wordNumber
        }
        if lhs.line != rhs.line {
            return lhs.line < rhs.line
        }
        return lhs.minX > rhs.minX
    }
}
