//
//  QuranPageFlowLayout.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/3/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class QuranPageFlowLayout: UICollectionViewFlowLayout {

    override func prepare() {
        itemSize = collectionSize()
        super.prepare()
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if newBounds.size != collectionSize() {
            itemSize = newBounds.size
            return true
        }
        return false
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if let visibleItem = collectionView?.indexPathsForVisibleItems.first,
            let attributes = layoutAttributesForItem(at: visibleItem) {

            return CGPoint(x: attributes.frame.minX, y: 0)
        } else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        }

    }

    fileprivate func collectionSize() -> CGSize {
        return collectionView?.bounds.size ?? CGSize.zero
    }
}
