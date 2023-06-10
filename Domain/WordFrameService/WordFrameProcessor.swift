//
//  WordFrameProcessor.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//

import QuranGeometry
import QuranKit
import UIKit

public struct WordFrameProcessor {
    public init() {
    }

    public func processWordFrames(
        _ wordFrames: WordFrameCollection,
        cropInsets: UIEdgeInsets
    ) -> WordFrameCollection {
        let frames = wordFrames.frames.flatMap(\.value).map { $0.withCropInsets(cropInsets) }

        // group by line
        var framesByLines = Dictionary(grouping: frames, by: { $0.line })
        let sortedLines = framesByLines.keys.sorted()

        framesByLines = sortFramesInEachLine(sortedLines, framesByLines)
        framesByLines = alignFramesVerticallyInEachLine(sortedLines, framesByLines)
        framesByLines = unionLinesVertically(sortedLines, framesByLines)
        framesByLines = unionFramesHorizontallyInEachLine(sortedLines, framesByLines)
        framesByLines = alignLineEdges(sortedLines, framesByLines)

        let framesDictionary = Dictionary(grouping: framesByLines.flatMap(\.value), by: { $0.word.verse })
        return WordFrameCollection(frames: framesDictionary)
    }

    private func sortFramesInEachLine(_ sortedLines: [Int], _ framesByLines: [Int: [WordFrame]]) -> [Int: [WordFrame]] {
        // sort each line from left to right
        var sortedFramesByLines: [Int: [WordFrame]] = [:]
        for line in sortedLines {
            let frames = framesByLines[line]!
            sortedFramesByLines[line] = frames.sorted { lhs, rhs in
                lhs.word < rhs.word
            }
        }
        return sortedFramesByLines
    }

    private func alignFramesVerticallyInEachLine(_ sortedLines: [Int], _ framesByLines: [Int: [WordFrame]]) -> [Int: [WordFrame]] {
        // align vertically each line
        var alignedFrames: [Int: [WordFrame]] = [:]
        for line in sortedLines {
            let list = framesByLines[line]!
            alignedFrames[line] = WordFrame.alignedVertically(list)
        }
        return alignedFrames
    }

    private func unionLinesVertically(_ sortedLines: [Int], _ framesByLines: [Int: [WordFrame]]) -> [Int: [WordFrame]] {
        // union each line with its neighbors
        var unionFrames: [Int: [WordFrame]] = framesByLines
        for i in 0 ..< sortedLines.count - 1 {
            let lineTop = sortedLines[i]
            var framesTop = unionFrames[lineTop]!

            let lineBottom = sortedLines[i + 1]
            var framesBottom = unionFrames[lineBottom]!

            WordFrame.unionVertically(top: &framesTop, bottom: &framesBottom)

            unionFrames[lineTop] = framesTop
            unionFrames[lineBottom] = framesBottom
        }
        return unionFrames
    }

    private func unionFramesHorizontallyInEachLine(_ sortedLines: [Int], _ framesByLines: [Int: [WordFrame]]) -> [Int: [WordFrame]] {
        // union each position with its neighbors
        var unionFrames: [Int: [WordFrame]] = [:]
        for line in sortedLines {
            var frames = framesByLines[line]!

            for j in 0 ..< frames.count - 1 {
                var first = frames[j]
                var second = frames[j + 1]
                first.unionHorizontally(left: &second)
                frames[j] = first
                frames[j + 1] = second
            }
            unionFrames[line] = frames
        }
        return unionFrames
    }

    private func alignLineEdges(_ sortedLines: [Dictionary<Int, [WordFrame]>.Keys.Element],
                                _ framesByLines: [Int: [WordFrame]]) -> [Int: [WordFrame]]
    {
        // align the edges
        var firstEdge = sortedLines.map { framesByLines[$0]!.first! }
        var lastEdge = sortedLines.map { framesByLines[$0]!.last! }
        WordFrame.unionLeftEdge(&lastEdge)
        WordFrame.unionRightEdge(&firstEdge)

        var alignedEdges: [Int: [WordFrame]] = [:]
        for i in 0 ..< sortedLines.count {
            let key = sortedLines[i]
            var list = framesByLines[key]!
            list[0] = firstEdge[i]
            list[list.count - 1] = lastEdge[i]
            alignedEdges[key] = list
        }
        return alignedEdges
    }
}
