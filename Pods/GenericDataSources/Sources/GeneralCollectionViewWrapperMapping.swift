//
//  GeneralCollectionViewWrapperMapping.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 9/16/15.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import UIKit

class GeneralCollectionViewWrapperMapping: GeneralCollectionViewMapping {
    
    let mapping: DataSourcesCollection.Mapping
    let delegate : GeneralCollectionView?

    init(mapping: DataSourcesCollection.Mapping, view: GeneralCollectionView) {
        self.mapping = mapping
        self.delegate = view
    }

    func globalSectionForLocalSection(_ localSection: Int) -> Int {
        return mapping.globalSectionForLocalSection(localSection)
    }
    
    func localIndexPathForGlobalIndexPath(_ globalIndexPath: IndexPath) -> IndexPath {
        return mapping.localIndexPathForGlobalIndexPath(globalIndexPath)
    }
    
    func globalIndexPathForLocalIndexPath(_ localIndexPath: IndexPath) -> IndexPath {
        return mapping.globalIndexPathForLocalIndexPath(localIndexPath)
    }
}
