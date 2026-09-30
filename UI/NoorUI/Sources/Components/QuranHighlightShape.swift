//
//  QuranHighlightShape.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import SwiftUI

/// A rounded highlight drawn around a verse or word on a Quran page.
///
/// `lineRects` holds one rectangle per line in the view's coordinate space. Rectangles that stack
/// vertically and overlap horizontally merge into one outline with rounded outer and inner corners;
/// the rest render as separate rounded pieces.
public struct QuranHighlightShape: Shape {
    // MARK: Lifecycle

    public init(lineRects: [CGRect], inset: CGSize = Self.verseInset) {
        self.lineRects = lineRects
        self.inset = inset
    }

    // MARK: Public

    /// Keeps neighboring verses in different colors visibly apart.
    public static let verseInset = CGSize(width: 1, height: 1)

    /// Keeps a word highlight inside the verse highlight it may sit on.
    public static let wordInset = CGSize(width: 1.5, height: 3)

    public let lineRects: [CGRect]
    public let inset: CGSize

    public static func word(_ rect: CGRect) -> Self {
        Self(lineRects: [rect], inset: wordInset)
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        for outline in QuranHighlightOutline.outlines(lineRects: lineRects, inset: inset) {
            path.addRoundedPolygon(outline.corners, cornerRadius: outline.cornerRadius)
        }
        return path
    }
}

struct QuranHighlightOutline: Equatable {
    // MARK: Internal

    /// Corner radius relative to the line height.
    static let cornerRadiusRatio: CGFloat = 0.2

    let corners: [CGPoint]
    let cornerRadius: CGFloat

    static func outlines(lineRects: [CGRect], inset: CGSize) -> [QuranHighlightOutline] {
        let rects = lineRects
            .filter { !$0.isEmpty }
            .sorted { $0.minY < $1.minY }
        guard let lineHeight = rects.map(\.height).min() else {
            return []
        }

        let cornerRadius = lineHeight * cornerRadiusRatio
        let minimumOverlap = 2 * (cornerRadius + inset.width)
        return connectedGroups(rects, minimumOverlap: minimumOverlap).map { group in
            QuranHighlightOutline(
                corners: corners(of: group, inset: inset),
                cornerRadius: cornerRadius
            )
        }
    }

    // MARK: Private

    private static let tolerance: CGFloat = 0.5

    /// Joins consecutive lines only when they touch and overlap enough to fit both corners.
    private static func connectedGroups(_ rects: [CGRect], minimumOverlap: CGFloat) -> [[CGRect]] {
        var groups: [[CGRect]] = []
        for rect in rects {
            if let previous = groups.last?.last,
               abs(previous.maxY - rect.minY) <= tolerance,
               min(previous.maxX, rect.maxX) - max(previous.minX, rect.minX) >= minimumOverlap
            {
                groups[groups.count - 1].append(rect)
            } else {
                groups.append([rect])
            }
        }
        return groups
    }

    /// Walks down the right side and back up the left side of the stacked lines, clockwise.
    private static func corners(of group: [CGRect], inset: CGSize) -> [CGPoint] {
        let rows = group.enumerated().map { index, rect in
            let top = index == 0 ? rect.minY + inset.height : rect.minY
            let bottom = index == group.count - 1 ? rect.maxY - inset.height : rect.maxY
            return (left: rect.minX + inset.width, right: rect.maxX - inset.width, top: top, bottom: bottom)
        }

        var points = [CGPoint(x: rows[0].left, y: rows[0].top), CGPoint(x: rows[0].right, y: rows[0].top)]
        for index in rows.indices {
            let bottom = index == rows.count - 1 ? rows[index].bottom : rows[index + 1].top
            points.append(CGPoint(x: rows[index].right, y: bottom))
            if index < rows.count - 1 {
                points.append(CGPoint(x: rows[index + 1].right, y: bottom))
            }
        }
        for index in rows.indices.reversed() {
            let bottom = index == rows.count - 1 ? rows[index].bottom : rows[index + 1].top
            points.append(CGPoint(x: rows[index].left, y: bottom))
            points.append(CGPoint(x: rows[index].left, y: rows[index].top))
        }
        return removingRedundantCorners(points)
    }

    /// Drops repeated points and points in the middle of a straight edge.
    private static func removingRedundantCorners(_ points: [CGPoint]) -> [CGPoint] {
        var result: [CGPoint] = []
        for point in points where result.last.map({ !$0.isClose(to: point) }) ?? true {
            result.append(point)
        }
        while result.count > 1, result[0].isClose(to: result[result.count - 1]) {
            result.removeLast()
        }

        var index = 0
        while result.count > 3, index < result.count {
            let previous = result[(index - 1 + result.count) % result.count]
            let current = result[index]
            let next = result[(index + 1) % result.count]
            let isVertical = abs(previous.x - current.x) < tolerance && abs(current.x - next.x) < tolerance
            let isHorizontal = abs(previous.y - current.y) < tolerance && abs(current.y - next.y) < tolerance
            if isVertical || isHorizontal {
                result.remove(at: index)
                index = 0
            } else {
                index += 1
            }
        }
        return result
    }
}

extension Path {
    /// Rounds every corner, convex or concave, clamping the radius to half of each adjacent edge.
    fileprivate mutating func addRoundedPolygon(_ corners: [CGPoint], cornerRadius: CGFloat) {
        guard corners.count >= 3 else {
            return
        }

        let count = corners.count
        move(to: corners[count - 1].midpoint(to: corners[0]))
        for index in corners.indices {
            let previous = corners[(index - 1 + count) % count]
            let corner = corners[index]
            let next = corners[(index + 1) % count]
            let radius = min(cornerRadius, corner.distance(to: previous) / 2, corner.distance(to: next) / 2)
            addArc(tangent1End: corner, tangent2End: next, radius: radius)
        }
        closeSubpath()
    }
}

extension CGPoint {
    fileprivate func isClose(to other: CGPoint) -> Bool {
        abs(x - other.x) < 0.01 && abs(y - other.y) < 0.01
    }

    fileprivate func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }

    fileprivate func midpoint(to other: CGPoint) -> CGPoint {
        CGPoint(x: (x + other.x) / 2, y: (y + other.y) / 2)
    }
}
