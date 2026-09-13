//
//  LinePageGeometryEngine.swift
//

import CoreGraphics
import Foundation
import QuranKit

public struct LinePageGeometryEngine {
    private struct Measurements {
        let pageWidth: CGFloat
        let pageHeight: CGFloat
        let headerFooterWidth: CGFloat
        let headerFooterHeight: CGFloat
        let sidelineWidth: CGFloat
    }

    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func layout(_ input: LinePageGeometryInput) -> LinePageLayout {
        let pageMeasurements = measurements(for: input)
        let contentSize = contentSize(for: input, pageMeasurements: pageMeasurements)
        let headerFooterWidth = input.displaySettings.showHeaderFooter ? pageMeasurements.headerFooterWidth : 0
        let headerFooterHeight = input.displaySettings.showHeaderFooter ? pageMeasurements.headerFooterHeight : 0

        let sidelineWidth = pageMeasurements.sidelineWidth
        let nonSidelinesWidth = input.availableSize.width - sidelineWidth
        let leadingSideline = input.displaySettings.showSidelines && input.pageParity == .odd
        let sidelineStartDelta = leadingSideline ? sidelineWidth : 0

        let headerX = sidelineStartDelta + ((nonSidelinesWidth - headerFooterWidth) / 2)
        let pageX = sidelineStartDelta + ((nonSidelinesWidth - pageMeasurements.pageWidth) / 2)

        let headerY: CGFloat
        let pageY: CGFloat
        let footerY: CGFloat

        switch input.orientation {
        case .portrait:
            let headerTop = (input.availableSize.height
                - headerFooterHeight
                - pageMeasurements.pageHeight
                - headerFooterHeight) / 2
            headerY = headerTop
            pageY = headerTop + headerFooterHeight
            footerY = pageY + pageMeasurements.pageHeight
        case .landscape:
            headerY = input.verticalPadding
            pageY = headerY + headerFooterHeight
            footerY = pageY + pageMeasurements.pageHeight
        }

        let headerFrame = CGRect(
            x: headerX,
            y: headerY,
            width: headerFooterWidth,
            height: headerFooterHeight
        )
        let pageFrame = CGRect(
            x: pageX,
            y: pageY,
            width: pageMeasurements.pageWidth,
            height: pageMeasurements.pageHeight
        )
        let footerFrame = CGRect(
            x: headerX,
            y: footerY,
            width: headerFooterWidth,
            height: headerFooterHeight
        )
        let sidelineFrame: CGRect? = if input.displaySettings.showSidelines {
            CGRect(
                x: leadingSideline ? 0 : (input.availableSize.width - sidelineWidth),
                y: pageY,
                width: sidelineWidth,
                height: pageMeasurements.pageHeight
            )
        } else {
            nil
        }

        let lineFrames = lineFrames(in: pageFrame, data: input.data)
        let lineDividers = lineDividers(
            for: lineFrames,
            enabled: input.displaySettings.showLineDividers
        )
        let versesByLine = Dictionary(grouping: input.data.highlightSpans, by: \.line)

        let highlightRects = highlightRects(
            for: input.highlights.highlightedVerses,
            spans: input.data.highlightSpans,
            in: pageFrame,
            data: input.data
        )
        let ayahMarkerPlacements = ayahMarkerPlacements(
            markers: input.data.ayahMarkers,
            in: pageFrame,
            data: input.data
        )
        let suraHeaderPlacements = suraHeaderPlacements(
            headers: input.data.suraHeaders,
            in: pageFrame,
            data: input.data,
            aspectRatio: input.suraHeaderAspectRatio
        )
        let sidelinePlacements = sidelinePlacements(
            for: input.data.sidelines,
            in: sidelineFrame,
            pageFrame: pageFrame,
            parity: input.pageParity,
            data: input.data
        )
        let selectionAnchorsByAyah = selectionAnchors(
            for: input.data.highlightSpans,
            in: pageFrame,
            data: input.data
        )
        let selectionLineRanges = selectionLineRanges(
            in: pageFrame,
            data: input.data
        )

        return LinePageLayout(
            contentSize: contentSize,
            headerFrame: headerFrame,
            pageFrame: pageFrame,
            footerFrame: footerFrame,
            sidelineFrame: sidelineFrame,
            lineFrames: lineFrames,
            highlightRects: highlightRects,
            ayahMarkerPlacements: ayahMarkerPlacements,
            suraHeaderPlacements: suraHeaderPlacements,
            sidelinePlacements: sidelinePlacements,
            lineDividers: lineDividers,
            versesByLine: versesByLine,
            selectionLineRanges: selectionLineRanges,
            selectionAnchorsByAyah: selectionAnchorsByAyah
        )
    }

    private func measurements(for input: LinePageGeometryInput) -> Measurements {
        let availableWidth = input.availableSize.width
        let availableHeight = input.availableSize.height
        let effectiveHeaderFooterHeightRatio = input.displaySettings.showHeaderFooter ? headerFooterHeightRatio : 0
        let minimumPageWidthToHeightRatio = 1 / minimumPageHeightToWidthRatio(data: input.data)

        let sidelineWidth = input.displaySettings.showSidelines
            ? floor(availableWidth * sidelineWidthRatio)
            : 0
        let layoutWidth = availableWidth - sidelineWidth

        switch input.orientation {
        case .portrait:
            let initialHeaderFooterHeight = floor(effectiveHeaderFooterHeightRatio * availableHeight)
            let initialPageHeight = availableHeight - (2 * initialHeaderFooterHeight)
            let computedWidth = floor(initialPageHeight * minimumPageWidthToHeightRatio)
            let pageWidth = min(layoutWidth, computedWidth)
            let maxPageHeight = round(pageWidth / pageMaxWidthToHeightRatio)

            let headerFooterHeight: CGFloat
            let pageHeight: CGFloat
            if initialPageHeight > maxPageHeight {
                headerFooterHeight = round((maxPageHeight + 2 * initialHeaderFooterHeight) * effectiveHeaderFooterHeightRatio)
                pageHeight = maxPageHeight
            } else {
                headerFooterHeight = initialHeaderFooterHeight
                pageHeight = initialPageHeight
            }

            let headerMargin = floor(pageWidth * headerFooterMarginRatio)
            return Measurements(
                pageWidth: pageWidth,
                pageHeight: pageHeight,
                headerFooterWidth: pageWidth - (2 * headerMargin),
                headerFooterHeight: headerFooterHeight,
                sidelineWidth: sidelineWidth
            )
        case .landscape:
            let pageWidth = min(scrollableMaximumPageWidth, round(layoutWidth * scrollablePageWidthRatio))
            let pageHeight = ceil(pageWidth * scrollablePageHeightToWidthRatio(data: input.data))
            let headerFooterHeight = floor(pageWidth * effectiveHeaderFooterHeightRatio)
            let headerMargin = floor(pageWidth * headerFooterMarginRatio)

            return Measurements(
                pageWidth: pageWidth,
                pageHeight: pageHeight,
                headerFooterWidth: pageWidth - (2 * headerMargin),
                headerFooterHeight: headerFooterHeight,
                sidelineWidth: sidelineWidth
            )
        }
    }

    private func contentSize(for input: LinePageGeometryInput, pageMeasurements: Measurements) -> CGSize {
        let headerFooterHeight = input.displaySettings.showHeaderFooter ? pageMeasurements.headerFooterHeight : 0

        switch input.orientation {
        case .portrait:
            return input.availableSize
        case .landscape:
            let contentInset = floor(headerFooterHeight * 0.5)
            return CGSize(
                width: input.availableSize.width,
                height: input.verticalPadding
                    + headerFooterHeight
                    + pageMeasurements.pageHeight
                    + headerFooterHeight
                    + input.verticalPadding
                    + contentInset
            )
        }
    }

    private func minimumPageHeightToWidthRatio(data: LinePageGeometryData) -> CGFloat {
        guard !data.metrics.allowLineOverlap else {
            return overlappingPageMinimumHeightToWidthRatio
        }

        return max(
            overlappingPageMinimumHeightToWidthRatio,
            CGFloat(data.lineCount) * CGFloat(data.metrics.lineHeightRatio)
        )
    }

    private func scrollablePageHeightToWidthRatio(data: LinePageGeometryData) -> CGFloat {
        max(
            scrollableOverlappingPageHeightToWidthRatio,
            minimumPageHeightToWidthRatio(data: data)
        )
    }

    // MARK: Lines and Selection

    private func lineFrames(in pageFrame: CGRect, data: LinePageGeometryData) -> [LinePageLineFrame] {
        let ranges = selectionLineRanges(in: pageFrame, data: data)
        return (0 ..< data.lineCount).map { lineIndex in
            LinePageLineFrame(
                lineNumber: lineIndex + 1,
                imageFrame: lineImageFrame(in: pageFrame, lineIndex: lineIndex, data: data),
                hitFrame: ranges[lineIndex].hitFrame
            )
        }
    }

    private func selectionLineRanges(in pageFrame: CGRect, data: LinePageGeometryData) -> [SelectionLineRange] {
        if data.metrics.allowLineOverlap {
            return overlappingSelectionLineRanges(in: pageFrame, data: data)
        }
        return nonOverlappingSelectionLineRanges(in: pageFrame, data: data)
    }

    private func overlappingSelectionLineRanges(in pageFrame: CGRect, data: LinePageGeometryData) -> [SelectionLineRange] {
        let height = Int(pageFrame.height)
        let lineHeight = Int(lineImageHeight(in: pageFrame, metrics: data.metrics))
        let lastLineIndex = max(data.lineCount - 1, 1)
        let lineHeightWithoutOverlap = (height - lineHeight) / lastLineIndex
        let offset = (lineHeight - lineHeightWithoutOverlap) / 2

        return (0 ..< data.lineCount).map { lineIndex in
            let fullLineStart = Int(floor(Double(height - lineHeight) / Double(lastLineIndex) * Double(lineIndex)))
            let hitY = fullLineStart + offset
            return SelectionLineRange(
                lineNumber: lineIndex,
                fullLineRange: CGFloat(fullLineStart) ... CGFloat(fullLineStart + lineHeight),
                hitFrame: CGRect(
                    x: pageFrame.minX,
                    y: pageFrame.minY + CGFloat(hitY),
                    width: pageFrame.width,
                    height: CGFloat(lineHeightWithoutOverlap)
                )
            )
        }
    }

    private func nonOverlappingSelectionLineRanges(in pageFrame: CGRect, data: LinePageGeometryData) -> [SelectionLineRange] {
        let slotHeight = lineSlotHeight(in: pageFrame, lineCount: data.lineCount)

        return (0 ..< data.lineCount).map { lineIndex in
            let lineStart = slotHeight * CGFloat(lineIndex)
            return SelectionLineRange(
                lineNumber: lineIndex,
                fullLineRange: lineStart ... (lineStart + slotHeight),
                hitFrame: CGRect(
                    x: pageFrame.minX,
                    y: pageFrame.minY + lineStart,
                    width: pageFrame.width,
                    height: slotHeight
                )
            )
        }
    }

    private func lineImageFrame(in pageFrame: CGRect, lineIndex: Int, data: LinePageGeometryData) -> CGRect {
        let imageLineHeight = lineImageHeight(in: pageFrame, metrics: data.metrics)
        let imageY: CGFloat

        if data.metrics.allowLineOverlap {
            let lastLineIndex = CGFloat(max(data.lineCount - 1, 1))
            imageY = floor((pageFrame.height - imageLineHeight) / lastLineIndex * CGFloat(lineIndex))
        } else {
            let slotHeight = lineSlotHeight(in: pageFrame, lineCount: data.lineCount)
            imageY = (slotHeight * CGFloat(lineIndex)) + ((slotHeight - imageLineHeight) / 2)
        }

        return CGRect(
            x: pageFrame.minX,
            y: pageFrame.minY + imageY,
            width: pageFrame.width,
            height: imageLineHeight
        )
    }

    private func lineContentFrame(in pageFrame: CGRect, lineIndex: Int, data: LinePageGeometryData) -> CGRect {
        guard data.metrics.allowLineOverlap else {
            return lineImageFrame(in: pageFrame, lineIndex: lineIndex, data: data)
        }

        let imageLineHeight = lineImageHeight(in: pageFrame, metrics: data.metrics)
        let lastLineIndex = CGFloat(max(data.lineCount - 1, 1))
        let imageY = ((pageFrame.height - imageLineHeight) / lastLineIndex) * CGFloat(lineIndex)
        return CGRect(
            x: pageFrame.minX,
            y: pageFrame.minY + imageY,
            width: pageFrame.width,
            height: imageLineHeight
        )
    }

    private func lineImageHeight(in pageFrame: CGRect, metrics: LinePageMetrics) -> CGFloat {
        pageFrame.width * CGFloat(metrics.lineHeightRatio)
    }

    private func lineSlotHeight(in pageFrame: CGRect, lineCount: Int) -> CGFloat {
        pageFrame.height / CGFloat(max(lineCount, 1))
    }

    private func lineDividers(for lineFrames: [LinePageLineFrame], enabled: Bool) -> [LinePageLineDivider] {
        guard enabled else {
            return []
        }

        return lineFrames.compactMap { lineFrame in
            guard lineFrame.lineNumber > 1 else {
                return nil
            }
            return LinePageLineDivider(
                lineNumber: lineFrame.lineNumber,
                frame: CGRect(
                    x: lineFrame.imageFrame.minX,
                    y: lineFrame.imageFrame.minY,
                    width: lineFrame.imageFrame.width,
                    height: lineDividerHeight
                )
            )
        }
    }

    private func selectionAnchors(
        for spans: [LinePageHighlightSpan],
        in pageFrame: CGRect,
        data: LinePageGeometryData
    ) -> [AyahNumber: LinePageSelectionAnchors] {
        let lineRanges = Dictionary(uniqueKeysWithValues: selectionLineRanges(in: pageFrame, data: data).map {
            ($0.lineNumber, $0.hitFrame)
        })

        let grouped = Dictionary(grouping: spans, by: \.ayah)
        return grouped.mapValues { spans in
            let ordered = spans.sorted {
                if $0.line == $1.line {
                    return $0.left < $1.left
                }
                return $0.line < $1.line
            }
            let start = selectionRect(for: ordered.first!, lineRanges: lineRanges, pageWidth: pageFrame.width)
            let end = selectionRect(for: ordered.last!, lineRanges: lineRanges, pageWidth: pageFrame.width)
            return LinePageSelectionAnchors(start: start, end: end)
        }
    }

    private func selectionRect(
        for span: LinePageHighlightSpan,
        lineRanges: [Int: CGRect],
        pageWidth: CGFloat
    ) -> CGRect {
        let hitFrame = lineRanges[span.line] ?? .zero
        let minX = hitFrame.minX + (span.left * pageWidth)
        let maxX = hitFrame.minX + (span.right * pageWidth)
        return CGRect(
            x: minX,
            y: hitFrame.minY,
            width: maxX - minX,
            height: hitFrame.height
        )
    }

    // MARK: Decorations

    private func highlightRects(
        for highlightedVerses: Set<AyahNumber>,
        spans: [LinePageHighlightSpan],
        in pageFrame: CGRect,
        data: LinePageGeometryData
    ) -> [LinePageHighlightRect] {
        guard !highlightedVerses.isEmpty else {
            return []
        }

        if data.metrics.allowLineOverlap {
            return overlappingHighlightRects(
                for: highlightedVerses,
                spans: spans,
                in: pageFrame,
                data: data
            )
        }

        let lineRanges = Dictionary(uniqueKeysWithValues: selectionLineRanges(in: pageFrame, data: data).map {
            ($0.lineNumber, $0.hitFrame)
        })

        return spans.compactMap { span in
            guard highlightedVerses.contains(span.ayah) else {
                return nil
            }
            guard let hitFrame = lineRanges[span.line] else {
                return nil
            }

            let x = hitFrame.minX + (span.left * pageFrame.width)
            let width = ceil((span.right - span.left) * pageFrame.width)
            return LinePageHighlightRect(
                ayah: span.ayah,
                rect: CGRect(x: x, y: hitFrame.minY, width: width, height: hitFrame.height)
            )
        }
    }

    private func overlappingHighlightRects(
        for highlightedVerses: Set<AyahNumber>,
        spans: [LinePageHighlightSpan],
        in pageFrame: CGRect,
        data: LinePageGeometryData
    ) -> [LinePageHighlightRect] {
        let drawLineHeight = lineImageHeight(in: pageFrame, metrics: data.metrics)
        let lastLineIndex = CGFloat(max(data.lineCount - 1, 1))
        let lineHeightWithoutOverlap = (pageFrame.height - drawLineHeight) / lastLineIndex
        let yStart = (drawLineHeight - lineHeightWithoutOverlap) / 2

        return spans.compactMap { span in
            guard highlightedVerses.contains(span.ayah) else {
                return nil
            }

            let lineIndex = CGFloat(span.line)
            let x = pageFrame.minX + (span.left * pageFrame.width)
            let width = ceil((span.right - span.left) * pageFrame.width)
            let y = pageFrame.minY + yStart + (lineHeightWithoutOverlap * lineIndex)
            return LinePageHighlightRect(
                ayah: span.ayah,
                rect: CGRect(x: x, y: y, width: width, height: lineHeightWithoutOverlap)
            )
        }
    }

    private func ayahMarkerPlacements(
        markers: [LinePageAyahMarker],
        in pageFrame: CGRect,
        data: LinePageGeometryData
    ) -> [LinePageAyahMarkerPlacement] {
        let markerDimension = 0.05 * pageFrame.width

        return markers.map { marker in
            let contentFrame = lineContentFrame(in: pageFrame, lineIndex: marker.line, data: data)
            let x = pageFrame.minX + ((marker.centerX * pageFrame.width) - (markerDimension / 2))
            let y = contentFrame.minY + (marker.centerY * contentFrame.height) - (markerDimension / 2)

            return LinePageAyahMarkerPlacement(
                marker: marker,
                frame: CGRect(x: x, y: y, width: markerDimension, height: markerDimension)
            )
        }
    }

    private func suraHeaderPlacements(
        headers: [LinePageSuraHeader],
        in pageFrame: CGRect,
        data: LinePageGeometryData,
        aspectRatio: CGFloat
    ) -> [LinePageSuraHeaderPlacement] {
        let width = pageFrame.width * suraHeaderWidthRatio
        let height = width * aspectRatio

        return headers.map { header in
            let contentFrame = lineContentFrame(in: pageFrame, lineIndex: header.line, data: data)
            let x = pageFrame.minX + ((header.centerX * pageFrame.width) - (width / 2))
            let y = contentFrame.minY + (header.centerY * contentFrame.height) - (height / 2)

            return LinePageSuraHeaderPlacement(
                header: header,
                frame: CGRect(x: x, y: y, width: width, height: height)
            )
        }
    }
}

private let headerFooterHeightRatio: CGFloat = 0.04
private let overlappingPageMinimumHeightToWidthRatio: CGFloat = 1.60
private let pageMaxWidthToHeightRatio: CGFloat = 1 / 1.84
private let headerFooterMarginRatio: CGFloat = 0.027
private let lineDividerHeight: CGFloat = 1
private let scrollablePageWidthRatio: CGFloat = 0.97
private let scrollableMaximumPageWidth: CGFloat = 1080
private let scrollableOverlappingPageHeightToWidthRatio: CGFloat = 1.76
private let sidelineWidthRatio: CGFloat = 0.1
private let suraHeaderWidthRatio: CGFloat = 1038 / 1080
