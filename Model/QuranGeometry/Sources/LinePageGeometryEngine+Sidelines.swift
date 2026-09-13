//
//  LinePageGeometryEngine+Sidelines.swift
//

import CoreGraphics
import Foundation
import QuranKit

extension LinePageGeometryEngine {
    func sidelinePlacements(
        for sidelines: [LinePageGeometryData.Sideline],
        in sidelineFrame: CGRect?,
        pageFrame: CGRect,
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
        let intrinsicScale = sidelineIntrinsicScale(in: pageFrame, metrics: data.metrics)
        let renderedIntrinsicSizes = sortedSidelines.map {
            renderedSidelineSize(for: $0, scale: intrinsicScale)
        }
        let lineHeight = sidelineFrame.height / CGFloat(max(data.lineCount, 1))

        let locations = sortedSidelines.enumerated().map { item -> ClosedRange<CGFloat> in
            let sideline = item.element
            let intrinsicSize = renderedIntrinsicSizes[item.offset]
            let targetLineTop = lineHeight * CGFloat(sideline.targetLine - 1)
            let y = if sideline.direction == .up {
                max(CGFloat.zero, targetLineTop + lineHeight - intrinsicSize.height)
            } else {
                targetLineTop
            }
            return y ... (y + intrinsicSize.height)
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
                lineCount: data.lineCount,
                renderedIntrinsicSize: renderedIntrinsicSizes[index],
                intrinsicScale: intrinsicScale,
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
        lineCount: Int,
        renderedIntrinsicSize: CGSize,
        intrinsicScale: CGFloat,
        metrics: LinePageMetrics
    ) -> CGSize {
        let intrinsic = sideline.intrinsicSize
        let renderedIntrinsic = renderedIntrinsicSize
        guard intrinsic.height > 0, renderedIntrinsic.height > 0 else {
            return .zero
        }

        let overlapsNext = locations.count > index + 1 && locations[index + 1].lowerBound < locations[index].upperBound

        if overlapsNext {
            let originalLinesSpanned = originalLinesSpanned(for: intrinsic, metrics: metrics)
            let nextUsedLine: Int = if sideline.direction == .up {
                (sortedSidelines.filter { $0.targetLine < sideline.targetLine }
                    .map(\.targetLine)
                    .max() ?? 1) - 1
            } else {
                (sortedSidelines.filter { $0.targetLine > sideline.targetLine }
                    .map(\.targetLine)
                    .min() ?? (lineCount + 1)) - 1
            }

            let targetLinesToSpan = max(originalLinesSpanned, abs(nextUsedLine - sideline.targetLine))
            let targetHeight = CGFloat(targetLinesToSpan) * lineHeight
            if renderedIntrinsic.height - targetHeight < (sidelineResizeThreshold * intrinsicScale) {
                return renderedIntrinsic
            }
            return CGSize(
                width: (targetHeight / renderedIntrinsic.height) * renderedIntrinsic.width,
                height: targetHeight
            )
        }

        if renderedIntrinsic.width > containerWidth {
            return CGSize(
                width: containerWidth,
                height: (containerWidth / renderedIntrinsic.width) * renderedIntrinsic.height
            )
        }

        let originalLinesSpanned = originalLinesSpanned(for: intrinsic, metrics: metrics)
        let originalTargetHeight = CGFloat(originalLinesSpanned) * lineHeight
        let targetHeight = abs(renderedIntrinsic.height + originalTargetHeight) / 2
        return CGSize(
            width: (targetHeight / renderedIntrinsic.height) * renderedIntrinsic.width,
            height: targetHeight
        )
    }

    private func sidelineIntrinsicScale(in pageFrame: CGRect, metrics: LinePageMetrics) -> CGFloat {
        guard metrics.widthParameter > 0 else {
            return 1
        }
        return pageFrame.width / CGFloat(metrics.widthParameter)
    }

    private func renderedSidelineSize(
        for sideline: LinePageGeometryData.Sideline,
        scale: CGFloat
    ) -> CGSize {
        CGSize(
            width: sideline.intrinsicSize.width * scale,
            height: sideline.intrinsicSize.height * scale
        )
    }

    private func originalLinesSpanned(for intrinsic: CGSize, metrics: LinePageMetrics) -> Int {
        guard metrics.intrinsicLineHeight > 0 else {
            return 1
        }
        return max(Int(ceil(intrinsic.height / (1.35 * CGFloat(metrics.intrinsicLineHeight)))), 1)
    }
}

private let sidelineResizeThreshold: CGFloat = 25
