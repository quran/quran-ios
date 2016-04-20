//
//  UnselectableSelectionHandler.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 3/28/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

public struct UnselectableSelectionHandler<ItemType, CellType: ReusableCell> : DataSourceSelectionHandler {

    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
}