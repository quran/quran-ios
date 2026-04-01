//
//  LinePageWordFrameAdapter.swift
//
//
//  Created by OpenAI Codex on 2026-03-31.
//

import CoreGraphics
import LinePagePersistence
import QuranGeometry
import QuranKit
import WordFrameService

public struct LinePageWordFrameAdapter {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func wordFrames(
        from highlightSpans: [LinePageHighlightSpan],
        quran: Quran,
        lineCount: Int
    ) -> WordFrameCollection {
        guard !highlightSpans.isEmpty else {
            return WordFrameCollection(lines: [])
        }

        let orderedSpans = highlightSpans.sorted(by: spanSort)
        var nextSegmentByAyah: [AyahNumber: Int] = [:]

        let frames = orderedSpans.map { span in
            let segmentNumber = nextSegmentByAyah[span.ayah, default: 0] + 1
            nextSegmentByAyah[span.ayah] = segmentNumber
            return syntheticWordFrame(for: span, quran: quran, lineCount: lineCount, segmentNumber: segmentNumber)
        }

        return processor.processWordFrames(frames)
    }

    // MARK: Private

    private static let pageWidth: CGFloat = 1080
    private static let pageHeightToWidthRatio: CGFloat = 1.76
    private static let lineHeightRatio: CGFloat = 174 / 1080

    private let processor = WordFrameProcessor()

    private func spanSort(_ lhs: LinePageHighlightSpan, _ rhs: LinePageHighlightSpan) -> Bool {
        if lhs.ayah != rhs.ayah {
            return lhs.ayah < rhs.ayah
        }
        if lhs.line != rhs.line {
            return lhs.line < rhs.line
        }
        // Preserve RTL ordering within the same line.
        return lhs.left > rhs.left
    }

    private func syntheticWordFrame(
        for span: LinePageHighlightSpan,
        quran: Quran,
        lineCount: Int,
        segmentNumber: Int
    ) -> WordFrame {
        let lineFrame = canonicalLineFrame(for: span.line, lineCount: lineCount)
        let minX = Int(floor(span.left * Self.pageWidth))
        let maxX = Int(ceil(span.right * Self.pageWidth))
        let minY = Int(floor(lineFrame.minY))
        let maxY = Int(ceil(lineFrame.maxY))

        return WordFrame(
            line: span.line + 1,
            word: Word(verse: span.ayah, wordNumber: segmentNumber),
            minX: minX,
            maxX: max(maxX, minX + 1),
            minY: minY,
            maxY: max(maxY, minY + 1)
        )
    }

    private func canonicalLineFrame(for lineIndex: Int, lineCount: Int) -> CGRect {
        let imageLineHeight = Self.pageWidth * Self.lineHeightRatio
        let pageHeight = Self.pageWidth * Self.pageHeightToWidthRatio
        let lastLineIndex = CGFloat(max(lineCount - 1, 1))
        let imageY = floor((pageHeight - imageLineHeight) / lastLineIndex * CGFloat(lineIndex))
        return CGRect(x: 0, y: imageY, width: Self.pageWidth, height: imageLineHeight)
    }
}
