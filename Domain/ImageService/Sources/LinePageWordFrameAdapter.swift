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
        metrics: LinePageMetrics = .madaniLinePages(widthParameter: 1080),
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
            return syntheticWordFrame(
                for: span,
                quran: quran,
                metrics: metrics,
                lineCount: lineCount,
                segmentNumber: segmentNumber
            )
        }

        return processor.processWordFrames(frames)
    }

    // MARK: Private

    private static let overlappingPageHeightToWidthRatio: CGFloat = 1.76

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
        metrics: LinePageMetrics,
        lineCount: Int,
        segmentNumber: Int
    ) -> WordFrame {
        let pageWidth = canonicalPageWidth(metrics: metrics)
        let lineFrame = canonicalLineFrame(for: span.line, metrics: metrics, lineCount: lineCount)
        let minX = Int(floor(span.left * pageWidth))
        let maxX = Int(ceil(span.right * pageWidth))
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

    private func canonicalLineFrame(for lineIndex: Int, metrics: LinePageMetrics, lineCount: Int) -> CGRect {
        let pageWidth = canonicalPageWidth(metrics: metrics)
        let pageHeight = canonicalPageHeight(metrics: metrics, lineCount: lineCount)
        let imageLineHeight = CGFloat(metrics.intrinsicLineHeight)
        let imageY: CGFloat

        if metrics.allowLineOverlap {
            let lastLineIndex = CGFloat(max(lineCount - 1, 1))
            imageY = floor((pageHeight - imageLineHeight) / lastLineIndex * CGFloat(lineIndex))
        } else {
            let slotHeight = pageHeight / CGFloat(max(lineCount, 1))
            imageY = (slotHeight * CGFloat(lineIndex)) + ((slotHeight - imageLineHeight) / 2)
        }

        return CGRect(x: 0, y: imageY, width: pageWidth, height: imageLineHeight)
    }

    private func canonicalPageWidth(metrics: LinePageMetrics) -> CGFloat {
        CGFloat(metrics.intrinsicLineHeight / metrics.lineHeightRatio)
    }

    private func canonicalPageHeight(metrics: LinePageMetrics, lineCount: Int) -> CGFloat {
        let pageWidth = canonicalPageWidth(metrics: metrics)
        let minimumHeightToWidthRatio: CGFloat = metrics.allowLineOverlap
            ? Self.overlappingPageHeightToWidthRatio
            : max(
                Self.overlappingPageHeightToWidthRatio,
                CGFloat(lineCount) * CGFloat(metrics.lineHeightRatio)
            )
        return pageWidth * minimumHeightToWidthRatio
    }
}
