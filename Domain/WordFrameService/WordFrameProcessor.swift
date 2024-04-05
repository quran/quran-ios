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
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func processWordFrames(
        _ wordFrames: [WordFrame],
        cropInsets: UIEdgeInsets
    ) -> WordFrameCollection {
        let frames = wordFrames.map { $0.withCropInsets(cropInsets) }

        // group by line
        let framesByLines = Dictionary(grouping: frames, by: { $0.line })
        var sortedLines = framesByLines
            .sorted { $0.key < $1.key }
            .map { line, wordFrames in
                wordFrames.sorted { $0.word < $1.word }
            }

        alignFramesVerticallyInEachLine(&sortedLines)
        unionLinesVertically(&sortedLines)
        unionFramesHorizontallyInEachLine(&sortedLines)
        alignLineEdges(&sortedLines)

        return WordFrameCollection(lines: sortedLines)
    }

    // MARK: Private

    private func alignFramesVerticallyInEachLine(_ lines: inout [[WordFrame]]) {
        // align vertically each line
        for i in 0 ..< lines.count {
            lines[i] = WordFrame.alignedVertically(lines[i])
        }
    }

    private func unionLinesVertically(_ lines: inout [[WordFrame]]) {
        // union each line with its neighbors
        for i in 0 ..< lines.count - 1 {
            // Create temporary copies
            var topFrames = lines[i]
            var bottomFrames = lines[i + 1]

            WordFrame.unionVertically(top: &topFrames, bottom: &bottomFrames)

            // Assign the modified copies back to the original array
            lines[i] = topFrames
            lines[i + 1] = bottomFrames
        }
    }

    private func unionFramesHorizontallyInEachLine(_ lines: inout [[WordFrame]]) {
        // union each position with its neighbors
        for i in 0 ..< lines.count {
            for j in 0 ..< lines[i].count - 1 {
                // Create temporary copies
                var left = lines[i][j]
                var right = lines[i][j + 1]

                left.unionHorizontally(left: &right)

                // Assign the modified copies back to the original array
                lines[i][j] = left
                lines[i][j + 1] = right
            }
        }
    }

    private func alignLineEdges(_ lines: inout [[WordFrame]]) {
        // align the edges
        var firstEdge = lines.map { $0.first! }
        var lastEdge = lines.map { $0.last! }
        WordFrame.unionLeftEdge(&lastEdge)
        WordFrame.unionRightEdge(&firstEdge)

        for i in 0 ..< lines.count {
            lines[i][0] = firstEdge[i]
            lines[i][lines[i].count - 1] = lastEdge[i]
        }
    }
}
