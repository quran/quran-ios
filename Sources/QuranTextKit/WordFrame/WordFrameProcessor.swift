//
//  WordFrameProcessor.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import PromiseKit
import QuranKit
import UIKit

protocol WordFrameProcessor {
    func processWordFrames(_ wordFrames: WordFrameCollection, cropInsets: UIEdgeInsets) -> WordFrameCollection
}

struct DefaultWordFrameProcessor: WordFrameProcessor {
    func processWordFrames(_ wordFrames: WordFrameCollection, cropInsets: UIEdgeInsets) -> WordFrameCollection {
        let frames = wordFrames.frames.mapValues { $0.map { $0.withCropInsets(cropInsets) } }

        // group by line
        var groupedLines = frames.flatMap(\.value).group { $0.line }
        let groupedLinesKeys = groupedLines.keys.sorted()

        // sort each line from left to right
        for i in 0 ..< groupedLinesKeys.count {
            let key = groupedLinesKeys[i]
            let value = groupedLines[key]!
            groupedLines[key] = value.sorted { lhs, rhs in
                lhs.word < rhs.word
            }
        }

        // align vertically each line
        for i in 0 ..< groupedLinesKeys.count {
            let key = groupedLinesKeys[i]
            let list = groupedLines[key]!
            groupedLines[key] = WordFrame.alignedVertically(list)
        }

        // union each line with its neighbors
        for i in 0 ..< groupedLinesKeys.count - 1 {
            let keyTop = groupedLinesKeys[i]
            let keyBottom = groupedLinesKeys[i + 1]
            var listTop = groupedLines[keyTop]!
            var listBottom = groupedLines[keyBottom]!
            WordFrame.unionVertically(top: &listTop, bottom: &listBottom)
            groupedLines[keyTop] = listTop
            groupedLines[keyBottom] = listBottom
        }

        // union each position with its neighbors
        for i in 0 ..< groupedLinesKeys.count {
            let key = groupedLinesKeys[i]
            var list = groupedLines[key]!

            for j in 0 ..< list.count - 1 {
                var first = list[j]
                var second = list[j + 1]
                first.unionHorizontally(left: &second)
                list[j] = first
                list[j + 1] = second
            }
            groupedLines[key] = list
        }

        // align the edges
        var firstEdge = groupedLines.map { $0.value[0] }
        var lastEdge = groupedLines.map { $0.value[$0.value.count - 1] }
        WordFrame.unionLeftEdge(&lastEdge)
        WordFrame.unionRightEdge(&firstEdge)
        for i in 0 ..< groupedLinesKeys.count {
            let key = groupedLinesKeys[i]
            var list = groupedLines[key]!
            list[0] = firstEdge[i]
            list[list.count - 1] = lastEdge[i]
            groupedLines[key] = list
        }

        return WordFrameCollection(frames: groupedLines.flatMap(\.value).group { $0.word.verse })
    }
}
