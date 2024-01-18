//
//  CollectionViewScroller.swift
//
//
//  Created by Mohamed Afifi on 2024-01-12.
//

import SwiftUI
import VLogging

@MainActor
final class CollectionViewScroller<
    SectionId: Hashable,
    Item: Identifiable & Hashable
> {
    init(collectionView: UICollectionView) {
        scrollToItemHelper = CollectionViewScrollToItemHelper(collectionView: collectionView)
        self.collectionView = collectionView
    }

    var dataSource: CollectionViewDataSource<SectionId, Item>?

    var onScrollAnchorIdUpdated: ((Item.ID) -> Void)?

    var isPagingEnabled: Bool = false {
        didSet {
            collectionView.decelerationRate = isPagingEnabled ? .fast : .normal
        }
    }

    private var transitioningToNewSize = false
    private var programmaticScrollingInProgress = false

    private let collectionView: UICollectionView
    private let scrollToItemHelper: CollectionViewScrollToItemHelper

    private var hasScrolledToInitialItem = false
    private var scrollAnchor: ScrollAnchor = .center
    private var scrollAnchorId: Item.ID? {
        didSet {
            assert(scrollAnchorId != nil, "scrollAnchorId shouldn't be nil")
            if let scrollAnchorId, oldValue != scrollAnchorId {
                onScrollAnchorIdUpdated?(scrollAnchorId)
            }
        }
    }

    private var isUserScrolling = false {
        didSet {
            if !isUserScrolling {
                updateScrollAnchorId()
            }
        }
    }
}

extension CollectionViewScroller {
    // MARK: - Pagingation

    func targetContentOffsetForProposedContentOffset(_ proposedContentOffset: CGPoint) -> CGPoint {
        if !isPagingEnabled {
            return proposedContentOffset
        }

        guard let scrollAnchorId, let anchorIndexPath = dataSource?.indexPath(for: scrollAnchorId) else {
            logger.error("targetContentOffset couldn't find the anchor with id: \(String(describing: scrollAnchorId))")
            return proposedContentOffset
        }

        let scrollsHorizontally = collectionView.scrollsHorizontally
        if scrollsHorizontally && collectionView.scrollsVertically {
            logger.error("isPagingEnabled doesn't support UICollectionView scrolling in both directions.")
            return proposedContentOffset
        }

        let targetIndexPaths = [
            collectionView.previousIndexPath(anchorIndexPath),
            anchorIndexPath,
            collectionView.nextIndexPath(anchorIndexPath),
        ].compactMap { $0 }

        let centeredContentOffset = collectionView.centeredContentOffset(proposedContentOffset)

        let indexPathDistances = targetIndexPaths.compactMap { indexPath in
            if let layoutAttributes = collectionView.layoutAttributesForItem(at: indexPath) {
                let distance = layoutAttributes.frame.squaredDistance(to: centeredContentOffset)
                return (layoutAttributes: layoutAttributes, distance: distance)
            }
            return nil
        }

        let targetLayoutAttributes = indexPathDistances.min { $0.distance < $1.distance }?.layoutAttributes
        if let targetLayoutAttributes {
            return collectionView.contentOffsetCentering(targetLayoutAttributes, proposedContentOffset: proposedContentOffset)
        } else {
            logger.error("targetContentOffset couldn't find layout attributes for the target nor the anchor.")
            return proposedContentOffset
        }
    }
}

extension CollectionViewScroller {
    // MARK: - Scroll Anchor

    func anchorScrollTo(id scrollAnchorId: Item.ID, anchor: ScrollAnchor) {
        let oldScrollAnchorId = self.scrollAnchorId
        self.scrollAnchorId = scrollAnchorId
        scrollAnchor = anchor

        // Animate to the new value, if changed.
        if scrollAnchorId != oldScrollAnchorId {
            scrollToAnchoredItem(animated: true)
        }
    }

    func animateToSize(_ size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // Update scroll item in case user scrolling is in progress.
        updateScrollAnchorId()

        transitioningToNewSize = true

        coordinator.animate(alongsideTransition: { _ in
            self.scrollToAnchoredItem(animated: false)
        }, completion: { _ in
            self.transitioningToNewSize = false
            self.scrollToAnchoredItem(animated: false)
        })
    }

    func scrollToAnchoredItemIfNeeded() {
        if transitioningToNewSize {
            scrollToAnchoredItem(animated: false)
        }
    }

    func scrollToInitialItemIfNeeded() {
        if !hasScrolledToInitialItem {
            hasScrolledToInitialItem = true
            if scrollAnchorId != nil {
                scrollToAnchoredItem(animated: false)

                if !isAnchorVisible {
                    // Try to scroll again, if first time failed to scroll.
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        self.collectionView.setNeedsLayout()
                        self.collectionView.layoutIfNeeded()
                        self.scrollToAnchoredItem(animated: false)
                    }
                }
            }
        }
    }

    func startInteractiveScrolling() {
        isUserScrolling = true
    }

    func endInteractiveScrolling() {
        // Give scroll view time to rest before calculating the new anchor.
        DispatchQueue.main.async {
            self.isUserScrolling = false
        }
    }
}

extension CollectionViewScroller {
    // MARK: - Helpers

    private func scrollToAnchoredItem(animated: Bool) {
        // Prevent rescursive anchoring.
        if programmaticScrollingInProgress {
            return
        }
        programmaticScrollingInProgress = true
        defer {
            DispatchQueue.main.async {
                self.programmaticScrollingInProgress = false
            }
        }

        if let scrollAnchorId,
           let scrollIndexPath = dataSource?.indexPath(for: scrollAnchorId),
           let scrollPositionOfScrollAnchor
        {
            scrollToItemHelper.accuratelyScrollToItem(at: scrollIndexPath, position: scrollPositionOfScrollAnchor, animated: animated)
            if !animated {
                collectionView.contentOffset = targetContentOffsetForProposedContentOffset(collectionView.contentOffset)
            }
        }
    }

    private func updateScrollAnchorId() {
        if let scrollIndex = indexPathClosestToAnchor {
            if let item = dataSource?.item(at: scrollIndex) {
                scrollAnchorId = item.id
            }
        }
    }

    private var isAnchorVisible: Bool {
        guard let scrollAnchorId else {
            return false
        }
        guard let anchorIndexPath = dataSource?.indexPath(for: scrollAnchorId) else {
            return false
        }
        return collectionView.indexPathsForVisibleItems.contains(anchorIndexPath)
    }

    private var indexPathClosestToAnchor: IndexPath? {
        let anchorPoint = anchorPoint
        let superviewAnchor = CGPoint(
            x: anchorPoint.x * collectionView.bounds.width + collectionView.frame.minX,
            y: anchorPoint.y * collectionView.bounds.height + collectionView.frame.minY
        )
        let collectionViewAnchor = collectionView.convert(superviewAnchor, from: collectionView.superview)
        return closestIndexPath(to: collectionViewAnchor)
    }

    private func closestIndexPath(to point: CGPoint) -> IndexPath? {
        // First, check if there's an item exactly at the point
        if let exactIndexPath = collectionView.indexPathForItem(at: point) {
            return exactIndexPath
        }

        let indexPathDistances = collectionView.indexPathsForVisibleItems.compactMap { indexPath in
            if let frame = collectionView.layoutAttributesForItem(at: indexPath)?.frame {
                let distance = frame.squaredDistance(to: point)
                return (indexPath: indexPath, distance: distance)
            }
            return nil
        }

        return indexPathDistances
            .min { $0.distance < $1.distance }
            .map(\.indexPath)
    }

    private var anchorPoint: UnitPoint {
        switch scrollAnchor {
        case .center:
            return UnitPoint(x: 0.5, y: 0.5)
        }
    }

    private var scrollPositionOfScrollAnchor: UICollectionView.ScrollPosition? {
        let scrollsHorizontally = collectionView.scrollsHorizontally
        let scrollsVertically = collectionView.scrollsVertically

        switch scrollAnchor {
        case .center:
            if scrollsVertically && !scrollsHorizontally {
                return .centeredVertically
            } else if !scrollsVertically && scrollsHorizontally {
                return .centeredHorizontally
            }
            return nil
        }
    }
}

private extension UICollectionView {
    var scrollsHorizontally: Bool {
        let availableWidth = bounds.width -
            adjustedContentInset.left -
            adjustedContentInset.right
        return contentSize.width > availableWidth
    }

    var scrollsVertically: Bool {
        let availableHeight = bounds.height -
            adjustedContentInset.top -
            adjustedContentInset.bottom

        return contentSize.height > availableHeight
    }

    func nextIndexPath(_ indexPath: IndexPath) -> IndexPath? {
        if indexPath.item < numberOfItems(inSection: indexPath.section) - 1 {
            // Next item in the same section
            return IndexPath(item: indexPath.item + 1, section: indexPath.section)
        } else if indexPath.section < numberOfSections - 1 {
            // First item in the next section
            return IndexPath(item: 0, section: indexPath.section + 1)
        } else {
            // Already at the last item of the last section
            return nil
        }
    }

    func previousIndexPath(_ indexPath: IndexPath) -> IndexPath? {
        if indexPath.item > 0 {
            // Previous item in the same section
            return IndexPath(item: indexPath.item - 1, section: indexPath.section)
        } else if indexPath.section > 0 {
            // Last item in the previous section
            let previousSection = indexPath.section - 1
            let lastItemInPreviousSection = numberOfItems(inSection: previousSection) - 1
            return IndexPath(item: lastItemInPreviousSection, section: previousSection)
        } else {
            // Already at the first item of the first section
            return nil
        }
    }

    func contentOffsetCentering(_ layoutAttributes: UICollectionViewLayoutAttributes, proposedContentOffset: CGPoint) -> CGPoint {
        let cellCenter = layoutAttributes.center
        if scrollsHorizontally {
            let offsetX = cellCenter.x - bounds.width / 2
            return CGPoint(x: offsetX, y: proposedContentOffset.y)
        } else {
            let offsetY = cellCenter.y - bounds.height / 2
            return CGPoint(x: proposedContentOffset.x, y: offsetY)
        }
    }

    func centeredContentOffset(_ contentOffset: CGPoint) -> CGPoint {
        CGPoint(
            x: contentOffset.x + bounds.width / 2,
            y: contentOffset.y + bounds.height / 2
        )
    }
}

private extension CGRect {
    func cornerClosest(to point: CGPoint) -> CGPoint {
        let closestX = max(minX, min(maxX, point.x))
        let closestY = max(minY, min(maxY, point.y))
        return CGPoint(x: closestX, y: closestY)
    }

    func squaredDistance(to point: CGPoint) -> CGFloat {
        let corner = cornerClosest(to: point)
        return UIx.squaredDistance(point, corner)
    }
}

private func squaredDistance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
    let deltaX = p2.x - p1.x
    let deltaY = p2.y - p1.y
    return deltaX * deltaX + deltaY * deltaY
}
