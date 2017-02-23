//
//  _CompositeParentGeneralCollectionViewMapping.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/21/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

class _CompositeParentGeneralCollectionViewMapping: _GeneralCollectionViewMapping {

    unowned var parentDataSource: CompositeDataSource

    unowned var dataSource: DataSource

    var delegate: GeneralCollectionView? {
        return parentDataSource.ds_reusableViewDelegate
    }

    init(dataSource: DataSource, parentDataSource: CompositeDataSource) {
        self.dataSource = dataSource
        self.parentDataSource = parentDataSource
    }

    func globalSectionForLocalSection(_ localSection: Int) -> Int {
        return parentDataSource.globalSectionForLocalSection(localSection, dataSource: dataSource)
    }

    func localIndexPathForGlobalIndexPath(_ globalIndexPath: IndexPath) -> IndexPath {
        return parentDataSource.localIndexPathForGlobalIndexPath(globalIndexPath, dataSource: dataSource)
    }

    func globalIndexPathForLocalIndexPath(_ localIndexPath: IndexPath) -> IndexPath {
        return parentDataSource.globalIndexPathForLocalIndexPath(localIndexPath, dataSource: dataSource)
    }
}
