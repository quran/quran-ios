//
//  _SegmentedGeneralCollectionViewMapping.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 11/13/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

class _SegmentedGeneralCollectionViewMapping: _GeneralCollectionViewMapping {

    unowned var parentDataSource: SegmentedDataSource

    var delegate: GeneralCollectionView? {
        return parentDataSource.ds_reusableViewDelegate
    }

    init(parentDataSource: SegmentedDataSource) {
        self.parentDataSource = parentDataSource
    }

    func globalSectionForLocalSection(_ localSection: Int) -> Int {
        return localSection
    }

    func localIndexPathForGlobalIndexPath(_ globalIndexPath: IndexPath) -> IndexPath {
        return globalIndexPath
    }

    func globalIndexPathForLocalIndexPath(_ localIndexPath: IndexPath) -> IndexPath {
        return localIndexPath
    }
}
