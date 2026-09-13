//
//  LinePageGeometryInput.swift
//

import CoreGraphics
import Foundation
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
    public init(
        showHeaderFooter: Bool = true,
        showSidelines: Bool = false,
        showLineDividers: Bool = false
    ) {
        self.showHeaderFooter = showHeaderFooter
        self.showSidelines = showSidelines
        self.showLineDividers = showLineDividers
    }

    public let showHeaderFooter: Bool
    public let showSidelines: Bool
    public let showLineDividers: Bool
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
            id: String,
            targetLine: Int,
            direction: LinePageSidelineDirection,
            intrinsicSize: CGSize
        ) {
            self.id = id
            self.targetLine = targetLine
            self.direction = direction
            self.intrinsicSize = intrinsicSize
        }

        public let id: String
        public let targetLine: Int
        public let direction: LinePageSidelineDirection
        /// Size in source asset pixels for the reading's width parameter.
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

public enum LinePageSidelineDirection: String, Sendable {
    case up
    case down
}
