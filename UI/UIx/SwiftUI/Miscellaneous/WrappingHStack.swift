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

        /// The cached rows.
        var rows: (Int, [Row])?
    }

    // MARK: Lifecycle

    /// Creates a wrapping horizontal stack with the given spacings and alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this stack. This guide has the same screen coordinate for every subview.
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

        let anchor = UnitPoint(alignment)

        for row in rows {
            for element in row.elements {
                let x: CGFloat = element.xOffset + anchor.x * (bounds.width - row.width)
                let y: CGFloat = row.yOffset + anchor.y * (row.height - element.size.height)
                let point = CGPoint(x: x + bounds.minX, y: y + bounds.minY)

                subviews[element.index].place(at: point, anchor: .topLeading, proposal: proposal)
            }
        }
    }
}

@available(iOS 16.0, *)
extension WrappingHStack {
    struct Row {
        var elements: [(index: Int, size: CGSize, xOffset: CGFloat)] = []
        var yOffset: CGFloat = .zero
        var width: CGFloat = .zero
        var height: CGFloat = .zero
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

        let sizes = subviews.map { $0.sizeThatFits(proposal) }

        let hash = computeHash(proposal: proposal, sizes: sizes)
        if let (oldHash, oldRows) = cache.rows,
           oldHash == hash
        {
            return oldRows
        }

        var currentX = CGFloat.zero
        var currentRow = Row()
        var rows = [Row]()

        for index in subviews.indices {
            var spacing = CGFloat.zero
            if let previousIndex = currentRow.elements.last?.index {
                spacing = horizontalSpacing(subviews[previousIndex], subviews[index])
            }

            let size = sizes[index]

            if currentX + size.width + spacing > proposal.width ?? .infinity,
               !currentRow.elements.isEmpty
            {
                currentRow.width = currentX
                rows.append(currentRow)
                currentRow = Row()
                spacing = .zero
                currentX = .zero
            }

            currentRow.elements.append((index, sizes[index], currentX + spacing))
            currentX += size.width + spacing
        }

        if !currentRow.elements.isEmpty {
            currentRow.width = currentX
            rows.append(currentRow)
        }

        var currentY = CGFloat.zero
        var previousMaxHeightIndex: Int?

        for index in rows.indices {
            let maxHeightIndex = rows[index].elements
                .max { $0.size.height < $1.size.height }!
                .index

            let size = sizes[maxHeightIndex]

            var spacing = CGFloat.zero
            if let previousMaxHeightIndex {
                spacing = verticalSpacing(subviews[previousMaxHeightIndex], subviews[maxHeightIndex])
            }

            rows[index].yOffset = currentY + spacing
            currentY += size.height + spacing
            rows[index].height = size.height
            previousMaxHeightIndex = maxHeightIndex
        }

        cache.rows = (hash, rows)

        return rows
    }

    private func computeHash(proposal: ProposedViewSize, sizes: [CGSize]) -> Int {
        let proposal = proposal.replacingUnspecifiedDimensions(by: .infinity)

        var hasher = Hasher()

        for size in [proposal] + sizes {
            hasher.combine(size.width)
            hasher.combine(size.height)
        }

        return hasher.finalize()
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

private extension CGSize {
    static var infinity: Self {
        .init(width: CGFloat.infinity, height: CGFloat.infinity)
    }
}

private extension UnitPoint {
    init(_ alignment: Alignment) {
        switch alignment {
        case .leading:
            self = .leading
        case .topLeading:
            self = .topLeading
        case .top:
            self = .top
        case .topTrailing:
            self = .topTrailing
        case .trailing:
            self = .trailing
        case .bottomTrailing:
            self = .bottomTrailing
        case .bottom:
            self = .bottom
        case .bottomLeading:
            self = .bottomLeading
        default:
            self = .center
        }
    }
}
