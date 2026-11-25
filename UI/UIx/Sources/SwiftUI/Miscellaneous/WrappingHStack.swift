//
//  WrappingHStack.swift
//  LayoutPlayground
//
//  Created by Konstantin Semianov on 11/30/22.
//

// From: https://github.com/ksemianov/WrappingHStack/blob/main/Sources/WrappingHStack/WrappingHStack.swift

import SwiftUI

/// A view that arranges its subviews in horizontal line and wraps them to the next lines if necessary.
@available(iOS 16.0, *)
public struct WrappingHStack: Layout {
    /// A shared computation between `sizeThatFits` and `placeSubviews`.
    public struct Cache {
        /// The minimal size of the view.
        var minSize: CGSize

        /// The cached rows, with the input they were arranged from.
        var rows: (input: RowsInput, rows: [Row])?
    }

    // MARK: Lifecycle

    /// Creates a wrapping horizontal stack with the given spacings and alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this stack. This guide has the same screen coordinate for every subview.
    ///     Its vertical guide aligns the subviews in each row, so `.firstTextBaseline` puts a row's text on one baseline.
    ///   - horizontalSpacing: The distance between adjacent subviews in a row or `nil` if you want the stack to choose a default distance.
    ///   - verticalSpacing: The distance between consequtive rows or`nil` if you want the stack to choose a default distance.
    ///   - fitContentWidth: Determines if the width of the stack should adjust to fit its content.
    ///   - content: A view builder that creates the content of this stack.
    @inlinable
    public init(
        alignment: Alignment = .center,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        fitContentWidth: Bool = false
    ) {
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.fitContentWidth = fitContentWidth
    }

    // MARK: Public

    public static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .horizontal

        return properties
    }

    /// The guide for aligning the subviews in this stack. This guide has the same screen coordinate for every subview.
    public var alignment: Alignment

    /// The distance between adjacent subviews in a row or `nil` if you want the stack to choose a default distance.
    public var horizontalSpacing: CGFloat?

    /// The distance between consequtive rows or`nil` if you want the stack to choose a default distance.
    public var verticalSpacing: CGFloat?

    /// Determines if the width of the stack should adjust to fit its content.
    ///
    /// If set to `true`, the stack's width will be based on its content rather than filling the available width.
    /// If set to `false` (default), it will occupy the full available width.
    public var fitContentWidth: Bool

    public func makeCache(subviews: Subviews) -> Cache {
        Cache(minSize: minSize(subviews: subviews))
    }

    public func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache.minSize = minSize(subviews: subviews)
        cache.rows = nil
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let rows = arrangeRows(proposal: proposal, subviews: subviews, cache: &cache)

        if rows.isEmpty { return cache.minSize }

        var width: CGFloat = rows.map(\.width).reduce(.zero) { max($0, $1) }

        if !fitContentWidth, let proposalWidth = proposal.width {
            width = max(width, proposalWidth)
        }

        var height: CGFloat = .zero
        if let lastRow = rows.last {
            height = lastRow.yOffset + lastRow.height
        }

        return CGSize(width: width, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let rows = arrangeRows(proposal: proposal, subviews: subviews, cache: &cache)

        let anchor = alignment.horizontal.fraction

        for row in rows {
            for element in row.elements {
                let x: CGFloat = element.xOffset + anchor * (bounds.width - row.width)
                let y: CGFloat = row.top(of: element.item)
                let point = CGPoint(x: x + bounds.minX, y: y + bounds.minY)

                subviews[element.index].place(at: point, anchor: .topLeading, proposal: proposal)
            }
        }
    }

    /// The first row's topmost first text baseline, and the last row's bottommost last text baseline. Other guides,
    /// including subviews' custom ones, take their defaults.
    public func explicitAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGFloat? {
        let isFirst = guide == .firstTextBaseline
        guard isFirst || guide == .lastTextBaseline else {
            return nil
        }
        let rows = arrangeRows(proposal: proposal, subviews: subviews, cache: &cache)
        guard let row = isFirst ? rows.first : rows.last else {
            return nil
        }
        let baselines = row.elements.compactMap { element in
            (isFirst ? element.item.firstTextBaseline : element.item.lastTextBaseline).map {
                bounds.minY + row.top(of: element.item) + $0
            }
        }
        return isFirst ? baselines.min() : baselines.max()
    }
}

@available(iOS 16.0, *)
extension WrappingHStack {
    /// A subview's measurements for a proposal, taken once per arrangement.
    struct Item: Equatable {
        var size: CGSize
        /// The subview's vertical alignment guide, from its top.
        var alignmentOffset: CGFloat
        var firstTextBaseline: CGFloat?
        var lastTextBaseline: CGFloat?
    }

    /// Everything the rows depend on, so cached rows are reused only for the same input.
    struct RowsInput: Equatable {
        var proposal: ProposedViewSize
        var verticalAlignment: VerticalAlignment
        var items: [Item]
    }

    struct Row {
        var elements: [(index: Int, item: Item, xOffset: CGFloat)] = []
        var yOffset: CGFloat = .zero
        var width: CGFloat = .zero
        var height: CGFloat = .zero
        /// The distance from the row's top to the line its elements' vertical alignment guides share.
        var alignmentOffset: CGFloat = .zero

        func top(of item: Item) -> CGFloat {
            yOffset + alignmentOffset - item.alignmentOffset
        }
    }

    private func arrangeRows(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> [Row] {
        if subviews.isEmpty {
            return []
        }

        if cache.minSize.width > proposal.width ?? .infinity,
           cache.minSize.height > proposal.height ?? .infinity
        {
            return []
        }

        let items = subviews.map { subview in
            let dimensions = subview.dimensions(in: proposal)
            return Item(
                size: CGSize(width: dimensions.width, height: dimensions.height),
                alignmentOffset: dimensions[alignment.vertical],
                firstTextBaseline: dimensions[explicit: .firstTextBaseline],
                lastTextBaseline: dimensions[explicit: .lastTextBaseline]
            )
        }

        let input = RowsInput(proposal: proposal, verticalAlignment: alignment.vertical, items: items)
        if let cached = cache.rows, cached.input == input {
            return cached.rows
        }

        var currentX = CGFloat.zero
        var currentRow = Row()
        var rows = [Row]()

        for index in subviews.indices {
            var spacing = CGFloat.zero
            if let previousIndex = currentRow.elements.last?.index {
                spacing = horizontalSpacing(subviews[previousIndex], subviews[index])
            }

            let size = items[index].size

            if currentX + size.width + spacing > proposal.width ?? .infinity,
               !currentRow.elements.isEmpty
            {
                currentRow.width = currentX
                rows.append(currentRow)
                currentRow = Row()
                spacing = .zero
                currentX = .zero
            }

            currentRow.elements.append((index, items[index], currentX + spacing))
            currentX += size.width + spacing
        }

        if !currentRow.elements.isEmpty {
            currentRow.width = currentX
            rows.append(currentRow)
        }

        var currentY = CGFloat.zero
        var previousMaxHeightIndex: Int?

        for index in rows.indices {
            let elements = rows[index].elements
            let maxHeightIndex = elements
                .max { $0.item.size.height < $1.item.size.height }!
                .index

            // Elements hang from the shared guide, so the row reaches from the highest top to the lowest bottom.
            let alignmentOffset = elements.map(\.item.alignmentOffset).max()!
            let height = elements.map { alignmentOffset - $0.item.alignmentOffset + $0.item.size.height }.max()!

            var spacing = CGFloat.zero
            if let previousMaxHeightIndex {
                spacing = verticalSpacing(subviews[previousMaxHeightIndex], subviews[maxHeightIndex])
            }

            rows[index].yOffset = currentY + spacing
            rows[index].alignmentOffset = alignmentOffset
            currentY += height + spacing
            rows[index].height = height
            previousMaxHeightIndex = maxHeightIndex
        }

        cache.rows = (input, rows)

        return rows
    }

    private func minSize(subviews: Subviews) -> CGSize {
        subviews
            .map { $0.sizeThatFits(.zero) }
            .reduce(CGSize.zero) { CGSize(width: max($0.width, $1.width), height: max($0.height, $1.height)) }
    }

    private func horizontalSpacing(_ lhs: LayoutSubview, _ rhs: LayoutSubview) -> CGFloat {
        if let horizontalSpacing { return horizontalSpacing }

        return lhs.spacing.distance(to: rhs.spacing, along: .horizontal)
    }

    private func verticalSpacing(_ lhs: LayoutSubview, _ rhs: LayoutSubview) -> CGFloat {
        if let verticalSpacing { return verticalSpacing }

        return lhs.spacing.distance(to: rhs.spacing, along: .vertical)
    }
}

private extension HorizontalAlignment {
    /// Where the guide sits across a row's free space: 0 at its leading edge, 1 at its trailing edge.
    var fraction: CGFloat {
        switch self {
        case .leading: 0
        case .trailing: 1
        default: 0.5
        }
    }
}
