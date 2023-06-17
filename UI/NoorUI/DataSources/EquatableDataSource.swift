//
//  EquatableDataSource.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/18/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

open class EquatableDataSource<ItemType: Equatable, CellType: ReusableCell>: BasicDataSource<ItemType, CellType> {
    // MARK: Public

    override public var items: [ItemType] {
        didSet {
            guard !updating else {
                return
            }
            if items != oldValue {
                ds_reusableViewDelegate?.ds_reloadSections(IndexSet(integer: 0), with: .automatic)
            } else {
                guard let collectionView = ds_reusableViewDelegate else {
                    return
                }
                let visibleIndexPaths = collectionView.ds_indexPathsForVisibleItems()
                for indexPath in visibleIndexPaths {
                    if let cell = ds_reusableViewDelegate?.ds_cellForItem(at: indexPath) as? CellType {
                        let item = item(at: indexPath)
                        ds_collectionView(collectionView, configure: cell, with: item, at: indexPath)
                    }
                }
            }
        }
    }

    // MARK: Internal

    func updatingItems(_ update: (inout [ItemType]) -> Void) {
        updating = true
        update(&items)
        updating = false
    }

    // MARK: Private

    private var updating: Bool = false
}
