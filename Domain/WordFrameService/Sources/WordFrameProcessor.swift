//
//  WordFrameProcessor.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//

import CoreGraphics
import QuranGeometry

public struct WordFrameProcessor {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func processWordFrames(_ frames: [WordFrame]) -> WordFrameCollection {
        guard !frames.isEmpty else {
            return WordFrameCollection(frames: [])
        }

        // group by line
        let framesByLines = Dictionary(grouping: frames, by: { $0.line })
        var lines = framesByLines
            .sorted { $0.key < $1.key }
            .map { _, wordFrames in wordFrames }

        normalize(&lines)
        alignFramesVerticallyInEachLine(&lines)
        unionLinesVertically(&lines)
        unionFramesHorizontallyInEachLine(&lines)
        alignLineEdges(&lines)

        return WordFrameCollection(frames: lines.flatMap { $0 })
    }

    /// The page's text extent in image coordinates: the median edges of the raw full lines, since processing
    /// stretches every line to the outermost glyphs. Nil when the text is too narrow to line up with.
    /// `tightenLine` narrows each line's box, such as to its ink.
    public func textColumn(
        _ frames: [WordFrame],
        imageWidth: CGFloat,
        tightenLine: (CGRect) -> CGRect
    ) -> ClosedRange<CGFloat>? {
        let lines = Dictionary(grouping: frames, by: \.line).values.map { frames in
            tightenLine(frames.map(\.rect).reduce(CGRect.null) { $0.union($1) })
        }
        guard !lines.isEmpty else {
            return nil
        }
        // Measured on every line: an opening page's few widest lines can reach the minimum on their own.
        let typical = Self.medianEdges(lines)
        guard typical.upperBound - typical.lowerBound >= Self.minimumTextWidthRatio * imageWidth else {
            return nil
        }
        return Self.medianEdges(Self.fullLines(lines))
    }

    // MARK: Private

    /// Opening pages measure at most 0.75 of the image width; other pages at least 0.84.
    private static let minimumTextWidthRatio: CGFloat = 0.8

    /// Lines at least 0.95 as wide as the 80th-percentile line, so short centred lines don't pull the edges in.
    /// The percentile skips the widest fifth, which an overhanging glyph can stretch. Justified lines agree
    /// within about 2%, while 1421 lines ending at an ayah marker, which its images leave out, fall 5–7% short.
    private static func fullLines(_ lines: [CGRect]) -> [CGRect] {
        let widths = lines.map(\.width).sorted()
        let reference = widths[min(widths.count - 1, Int(CGFloat(widths.count) * 0.8))]
        return lines.filter { $0.width >= 0.95 * reference }
    }

    private static func medianEdges(_ lines: [CGRect]) -> ClosedRange<CGFloat> {
        median(lines.map(\.minX)) ... median(lines.map(\.maxX))
    }

    private static func median(_ values: [CGFloat]) -> CGFloat {
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }

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
        var rightEdge = lines.map { $0[0] }
        var leftEdge = lines.map { $0[$0.count - 1] }
        WordFrame.unionLeftEdge(&leftEdge)
        WordFrame.unionRightEdge(&rightEdge)

        for i in 0 ..< lines.count {
            lines[i][0] = rightEdge[i]
            lines[i][lines[i].count - 1] = leftEdge[i]
        }
    }
}
