//
//  LinePageGeometry.swift
//
//
//  Created by Mohamed Afifi on 2026-03-29.
//

import CoreGraphics
import Foundation
import LinePagePersistence
import QuranKit

public enum LinePageOrientation: Sendable {
    case portrait
    case landscape
}

public enum LinePageParity: Sendable {
    case odd
    case even
}

public struct LinePageDisplaySettings: Sendable {
    public init(showHeaderFooter: Bool = true, showSidelines: Bool = false) {
        self.showHeaderFooter = showHeaderFooter
        self.showSidelines = showSidelines
    }

    public let showHeaderFooter: Bool
    public let showSidelines: Bool
}

public struct LinePageHighlightState: Sendable {
    public init(highlightedVerses: Set<AyahNumber> = []) {
        self.highlightedVerses = highlightedVerses
    }

    public let highlightedVerses: Set<AyahNumber>
}

public struct LinePageGeometryData: Sendable {
    public struct Sideline: Hashable, Sendable {
        public init(
            id: String = "",
            targetLine: Int,
            direction: LinePageAssets.SidelineDirection,
            intrinsicSize: CGSize
        ) {
            self.id = id
            self.targetLine = targetLine
            self.direction = direction
            self.intrinsicSize = intrinsicSize
        }

        public let id: String
        public let targetLine: Int
        public let direction: LinePageAssets.SidelineDirection
        public let intrinsicSize: CGSize
    }

    public init(
        metrics: LinePageMetrics = .madaniLinePages(widthParameter: 1080),
        lineCount: Int? = nil,
        highlightSpans: [LinePageHighlightSpan],
        ayahMarkers: [LinePageAyahMarker],
        suraHeaders: [LinePageSuraHeader],
        sidelines: [Sideline]
    ) {
        self.metrics = metrics
        self.lineCount = lineCount ?? metrics.lineCount
        self.highlightSpans = highlightSpans
        self.ayahMarkers = ayahMarkers
        self.suraHeaders = suraHeaders
        self.sidelines = sidelines
    }

    public let metrics: LinePageMetrics
    public let lineCount: Int
    public let highlightSpans: [LinePageHighlightSpan]
    public let ayahMarkers: [LinePageAyahMarker]
    public let suraHeaders: [LinePageSuraHeader]
    public let sidelines: [Sideline]
}

public struct LinePageGeometryInput: Sendable {
    public init(
        availableSize: CGSize,
        orientation: LinePageOrientation,
        verticalPadding: CGFloat = 0,
        pageParity: LinePageParity,
        displaySettings: LinePageDisplaySettings,
        data: LinePageGeometryData,
        highlights: LinePageHighlightState = LinePageHighlightState(),
        suraHeaderAspectRatio: CGFloat
    ) {
        self.availableSize = availableSize
        self.orientation = orientation
        self.verticalPadding = verticalPadding
        self.pageParity = pageParity
        self.displaySettings = displaySettings
        self.data = data
        self.highlights = highlights
        self.suraHeaderAspectRatio = suraHeaderAspectRatio
    }

    public let availableSize: CGSize
    public let orientation: LinePageOrientation
    public let verticalPadding: CGFloat
    public let pageParity: LinePageParity
    public let displaySettings: LinePageDisplaySettings
    public let data: LinePageGeometryData
    public let highlights: LinePageHighlightState
    public let suraHeaderAspectRatio: CGFloat
}

public struct LinePageLineFrame: Hashable, Sendable {
    public init(lineNumber: Int, imageFrame: CGRect, hitFrame: CGRect) {
        self.lineNumber = lineNumber
        self.imageFrame = imageFrame
        self.hitFrame = hitFrame
    }

    public let lineNumber: Int
    public let imageFrame: CGRect
    public let hitFrame: CGRect
}

public struct LinePageHighlightRect: Hashable, Sendable {
    public init(ayah: AyahNumber, rect: CGRect) {
        self.ayah = ayah
        self.rect = rect
    }

    public let ayah: AyahNumber
    public let rect: CGRect
}

public struct LinePageAyahMarkerPlacement: Hashable, Sendable {
    public init(marker: LinePageAyahMarker, frame: CGRect) {
        self.marker = marker
        self.frame = frame
    }

    public let marker: LinePageAyahMarker
    public let frame: CGRect
}

public struct LinePageSuraHeaderPlacement: Hashable, Sendable {
    public init(header: LinePageSuraHeader, frame: CGRect) {
        self.header = header
        self.frame = frame
    }

    public let header: LinePageSuraHeader
    public let frame: CGRect
}

public struct LinePageSidelinePlacement: Hashable, Sendable {
    public init(sideline: LinePageGeometryData.Sideline, frame: CGRect) {
        self.sideline = sideline
        self.frame = frame
    }

    public let sideline: LinePageGeometryData.Sideline
    public let frame: CGRect
}

public struct LinePageSelectionAnchors: Hashable, Sendable {
    public init(start: CGRect, end: CGRect) {
        self.start = start
        self.end = end
    }

    public let start: CGRect
    public let end: CGRect
}

public struct LinePageLayout: Sendable {
    // MARK: Lifecycle

    fileprivate init(
        contentSize: CGSize,
        headerFrame: CGRect,
        pageFrame: CGRect,
        footerFrame: CGRect,
        sidelineFrame: CGRect?,
        lineFrames: [LinePageLineFrame],
        highlightRects: [LinePageHighlightRect],
        ayahMarkerPlacements: [LinePageAyahMarkerPlacement],
        suraHeaderPlacements: [LinePageSuraHeaderPlacement],
        sidelinePlacements: [LinePageSidelinePlacement],
        versesByLine: [Int: [LinePageHighlightSpan]],
        selectionLineRanges: [SelectionLineRange],
        selectionAnchorsByAyah: [AyahNumber: LinePageSelectionAnchors]
    ) {
        self.contentSize = contentSize
        self.headerFrame = headerFrame
        self.pageFrame = pageFrame
        self.footerFrame = footerFrame
        self.sidelineFrame = sidelineFrame
        self.lineFrames = lineFrames
        self.highlightRects = highlightRects
        self.ayahMarkerPlacements = ayahMarkerPlacements
        self.suraHeaderPlacements = suraHeaderPlacements
        self.sidelinePlacements = sidelinePlacements
        self.versesByLine = versesByLine
        self.selectionLineRanges = selectionLineRanges
        self.selectionAnchorsByAyah = selectionAnchorsByAyah
    }

    // MARK: Public

    public let contentSize: CGSize
    public let headerFrame: CGRect
    public let pageFrame: CGRect
    public let footerFrame: CGRect
    public let sidelineFrame: CGRect?
    public let lineFrames: [LinePageLineFrame]
    public let highlightRects: [LinePageHighlightRect]
    public let ayahMarkerPlacements: [LinePageAyahMarkerPlacement]
    public let suraHeaderPlacements: [LinePageSuraHeaderPlacement]
    public let sidelinePlacements: [LinePageSidelinePlacement]

    public func verse(at point: CGPoint) -> AyahNumber? {
        guard pageFrame.contains(point) else {
            return nil
        }

        let localPoint = CGPoint(x: point.x - pageFrame.minX, y: point.y - pageFrame.minY)
        guard let lineRange = selectionLineRanges.first(where: { $0.fullLineRange.contains(localPoint.y) }) else {
            return nil
        }

        let matches = versesByLine[lineRange.lineNumber, default: []]
            .filter {
                let left = $0.left * pageFrame.width
                let right = $0.right * pageFrame.width
                return (left ... right).contains(localPoint.x)
            }
            .map(\.ayah)
        return matches.max()
    }

    public func selectionAnchors(for ayah: AyahNumber) -> LinePageSelectionAnchors? {
        selectionAnchorsByAyah[ayah]
    }

    // MARK: Private

    private let versesByLine: [Int: [LinePageHighlightSpan]]
    private let selectionLineRanges: [SelectionLineRange]
    private let selectionAnchorsByAyah: [AyahNumber: LinePageSelectionAnchors]
}

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
            versesByLine: versesByLine,
            selectionLineRanges: selectionLineRanges,
            selectionAnchorsByAyah: selectionAnchorsByAyah
        )
    }

    // MARK: Private

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
        let width = Int(pageFrame.width)
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

    private func sidelinePlacements(
        for sidelines: [LinePageGeometryData.Sideline],
        in sidelineFrame: CGRect?,
        parity: LinePageParity,
        data: LinePageGeometryData
    ) -> [LinePageSidelinePlacement] {
        guard let sidelineFrame else {
            return []
        }

        let sortedSidelines = sidelines.sorted { lhs, rhs in
            if lhs.targetLine == rhs.targetLine {
                return lhs.intrinsicSize.height < rhs.intrinsicSize.height
            }
            return lhs.targetLine < rhs.targetLine
        }
        let lineHeight = sidelineFrame.height / CGFloat(max(data.lineCount, 1))

        let locations = sortedSidelines.map { sideline -> ClosedRange<CGFloat> in
            let targetLineTop = lineHeight * CGFloat(sideline.targetLine - 1)
            let y = if sideline.direction == .up {
                max(CGFloat.zero, targetLineTop + lineHeight - sideline.intrinsicSize.height)
            } else {
                targetLineTop
            }
            return y ... (y + sideline.intrinsicSize.height)
        }

        return sortedSidelines.enumerated().map { item in
            let index = item.offset
            let sideline = item.element
            let location = locations[index]
            let size = sidelineSize(
                for: sideline,
                at: index,
                sortedSidelines: sortedSidelines,
                locations: locations,
                containerWidth: sidelineFrame.width,
                lineHeight: lineHeight,
                metrics: data.metrics
            )

            let y: CGFloat
            if locations.count > index + 1, locations[index + 1].lowerBound < (location.lowerBound + size.height) {
                let updatedY = location.lowerBound + size.height
                y = location.lowerBound - (updatedY - locations[index + 1].lowerBound)
            } else if location.lowerBound + size.height > sidelineFrame.height {
                y = location.lowerBound - ((location.lowerBound + size.height) - sidelineFrame.height)
            } else {
                y = location.lowerBound
            }

            let x = if parity == .odd {
                sidelineFrame.width - size.width
            } else {
                CGFloat.zero
            }

            return LinePageSidelinePlacement(
                sideline: sideline,
                frame: CGRect(
                    x: sidelineFrame.minX + x,
                    y: sidelineFrame.minY + y,
                    width: size.width,
                    height: size.height
                )
            )
        }
    }

    private func sidelineSize(
        for sideline: LinePageGeometryData.Sideline,
        at index: Int,
        sortedSidelines: [LinePageGeometryData.Sideline],
        locations: [ClosedRange<CGFloat>],
        containerWidth: CGFloat,
        lineHeight: CGFloat,
        metrics: LinePageMetrics
    ) -> CGSize {
        let intrinsic = sideline.intrinsicSize
        let overlapsNext = locations.count > index + 1 && locations[index + 1].lowerBound < locations[index].upperBound

        if overlapsNext {
            let originalLinesSpanned = Int(ceil(intrinsic.height / (1.35 * CGFloat(metrics.intrinsicLineHeight))))
            let nextUsedLine: Int = if sideline.direction == .up {
                (sortedSidelines.filter { $0.targetLine < sideline.targetLine }
                    .map(\.targetLine)
                    .max() ?? 1) - 1
            } else {
                (sortedSidelines.filter { $0.targetLine > sideline.targetLine }
                    .map(\.targetLine)
                    .min() ?? 16) - 1
            }

            let targetLinesToSpan = max(originalLinesSpanned, abs(nextUsedLine - sideline.targetLine))
            let targetHeight = CGFloat(targetLinesToSpan) * lineHeight
            if intrinsic.height - targetHeight < 25 {
                return intrinsic
            }
            return CGSize(
                width: (targetHeight / intrinsic.height) * intrinsic.width,
                height: targetHeight
            )
        }

        if intrinsic.width > containerWidth {
            return CGSize(
                width: containerWidth,
                height: (containerWidth / intrinsic.width) * intrinsic.height
            )
        }

        let originalLinesSpanned = Int(ceil(intrinsic.height / (1.35 * CGFloat(metrics.intrinsicLineHeight))))
        let originalTargetHeight = CGFloat(originalLinesSpanned) * lineHeight
        let targetHeight = abs(intrinsic.height + originalTargetHeight) / 2
        return CGSize(
            width: (targetHeight / intrinsic.height) * intrinsic.width,
            height: targetHeight
        )
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
}

private struct SelectionLineRange: Sendable {
    let lineNumber: Int
    let fullLineRange: ClosedRange<CGFloat>
    let hitFrame: CGRect
}

private let headerFooterHeightRatio: CGFloat = 0.04
private let overlappingPageMinimumHeightToWidthRatio: CGFloat = 1.60
private let pageMaxWidthToHeightRatio: CGFloat = 1 / 1.84
private let headerFooterMarginRatio: CGFloat = 0.027
private let scrollablePageWidthRatio: CGFloat = 0.97
private let scrollableMaximumPageWidth: CGFloat = 1080
private let scrollableOverlappingPageHeightToWidthRatio: CGFloat = 1.76
private let sidelineWidthRatio: CGFloat = 0.1
private let suraHeaderWidthRatio: CGFloat = 1038 / 1080
