//
//  QuranPageFlowLayout.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/3/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
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
