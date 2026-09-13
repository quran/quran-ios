//
//  LinePageLayout.swift
//

import CoreGraphics
import Foundation
import QuranKit

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

public struct LinePageLineDivider: Hashable, Sendable {
    public init(lineNumber: Int, frame: CGRect) {
        self.lineNumber = lineNumber
        self.frame = frame
    }

    public let lineNumber: Int
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

    init(
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
        lineDividers: [LinePageLineDivider],
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
        self.lineDividers = lineDividers
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
    public let lineDividers: [LinePageLineDivider]

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

struct SelectionLineRange: Sendable {
    let lineNumber: Int
    let fullLineRange: ClosedRange<CGFloat>
    let hitFrame: CGRect
}
