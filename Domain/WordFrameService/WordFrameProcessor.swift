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
        guard !wordFrames.isEmpty else {
            return WordFrameCollection(lines: [])
        }
        let frames = wordFrames.map { $0.withCropInsets(cropInsets) }

        // group by line
        let framesByLines = Dictionary(grouping: frames, by: { $0.line })
        var sortedLines = framesByLines
            .sorted { $0.key < $1.key }
            .map { _, wordFrames in wordFrames }

        normalize(&sortedLines)
        alignFramesVerticallyInEachLine(&sortedLines)
        unionLinesVertically(&sortedLines)
        unionFramesHorizontallyInEachLine(&sortedLines)
        alignLineEdges(&sortedLines)

        return WordFrameCollection(lines: sortedLines)
    }

    // MARK: Private

    private func normalize(_ lines: inout [[WordFrame]]) {
        for i in 0 ..< lines.count {
            for j in 0 ..< lines[i].count {
                lines[i][j].normalize()
            }
        }
    }

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
        for lineIndex in 0 ..< lines.count {
            // Sort frames in the current line based on minX to ensure they are in decreasing order
            lines[lineIndex].sort(by: { $0.minX > $1.minX })

            for frameIndex in 0 ..< lines[lineIndex].count - 1 {
                var leftFrame = lines[lineIndex][frameIndex + 1]
                var rightFrame = lines[lineIndex][frameIndex + 0]

                // Ensure the frames touch each other without gaps or overlaps
                WordFrame.unionHorizontally(leftFrame: &leftFrame, rightFrame: &rightFrame)

                // Update the frames in the current line
                lines[lineIndex][frameIndex + 1] = leftFrame
                lines[lineIndex][frameIndex + 0] = rightFrame
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
