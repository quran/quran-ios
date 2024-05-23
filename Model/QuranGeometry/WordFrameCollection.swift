//
//  WordFrameCollection.swift
//
//
//  Created by Mohamed Afifi on 2021-12-26.
//

import Foundation
import QuranKit

public struct WordFrameCollection: Equatable {
    public var lines: [WordFrameLine]

    public init(lines: [WordFrameLine]) {
        self.lines = lines
    }

    public func wordFramesForVerse(_ verse: AyahNumber) -> [WordFrame] {
        lines
            .flatMap(\.frames)
            .filter { $0.word.verse == verse }
    }

    public func lineFramesVerVerse(_ verse: AyahNumber) -> [WordFrameLine] {
        lines.filter { line in
            line.frames.contains { $0.word.verse == verse }
        }
    }

    public func wordFrameForWord(_ word: Word) -> WordFrame? {
        let frames = wordFramesForVerse(word.verse)
        return frames.first(where: { $0.word == word })
    }

    public func wordAtLocation(_ location: CGPoint, imageScale: WordFrameScale) -> Word? {
        let flattenFrames = lines.flatMap(\.frames)
        for frame in flattenFrames {
            let rectangle = frame.rect.scaled(by: imageScale)
            if rectangle.contains(location) {
                return frame.word
            }
        }
        return nil
    }

    public func topPadding(atLineIndex lineIndex: Int, scale: WordFrameScale) -> CGFloat {
        let topLine = lineIndex == 0 ? 0 : lines[lineIndex - 1].frames[0].maxY
        let padding = CGFloat(lines[lineIndex].frames[0].minY - topLine)
        return padding * scale.scale
    }
}
