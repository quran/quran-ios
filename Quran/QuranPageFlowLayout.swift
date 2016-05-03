//
//  QuranPageFlowLayout.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/3/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class QuranPageFlowLayout: UICollectionViewFlowLayout {

    override func prepareLayout() {
        itemSize = collectionSize()
        super.prepareLayout()
    }

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        if newBounds.size != collectionSize() {
            itemSize = newBounds.size
            return true
        }
        return false
    }

    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
        if let visibleItem = collectionView?.indexPathsForVisibleItems().first,
            let attributes = layoutAttributesForItemAtIndexPath(visibleItem) {

            return CGPoint(x: attributes.frame.minX, y: 0)
        } else {
            return super.targetContentOffsetForProposedContentOffset(proposedContentOffset)
        }

    }

    private func collectionSize() -> CGSize {
        return collectionView?.bounds.size ?? CGSize.zero
    }
}
