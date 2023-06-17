//
//  BasicDataSource+Selection.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

extension BasicDataSource {
    func addSelectionHandler() -> BlockSelectionHandler<ItemType, CellType> {
        let handler = BlockSelectionHandler<ItemType, CellType>()
        setSelectionHandler(handler)
        return handler
    }

    public func setDidSelect(_ didSelect: @escaping (BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Void) {
        addSelectionHandler().didSelectBlock = didSelect
    }
}
