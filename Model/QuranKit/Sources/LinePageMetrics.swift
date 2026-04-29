//
//  LinePageMetrics.swift
//
//
//  Created by OpenAI on 2026-04-26.
//

public struct LinePageMetrics: Equatable, Sendable {
    // MARK: Lifecycle

    public init(
        widthParameter: Int,
        lineCount: Int,
        lineHeightRatio: Double,
        intrinsicLineHeight: Double,
        allowLineOverlap: Bool
    ) {
        self.widthParameter = widthParameter
        self.lineCount = lineCount
        self.lineHeightRatio = lineHeightRatio
        self.intrinsicLineHeight = intrinsicLineHeight
        self.allowLineOverlap = allowLineOverlap
    }

    // MARK: Public

    public let widthParameter: Int
    public let lineCount: Int
    public let lineHeightRatio: Double
    public let intrinsicLineHeight: Double
    public let allowLineOverlap: Bool

    public static func madaniLinePages(widthParameter: Int) -> LinePageMetrics {
        LinePageMetrics(
            widthParameter: widthParameter,
            lineCount: 15,
            lineHeightRatio: 174 / 1080,
            intrinsicLineHeight: 174,
            allowLineOverlap: true
        )
    }

    public static let naskhLinePages = LinePageMetrics(
        widthParameter: 1342,
        lineCount: 15,
        lineHeightRatio: 148 / 1342,
        intrinsicLineHeight: 148,
        allowLineOverlap: false
    )
}
