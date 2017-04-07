//
//  UnselectableSelectionHandler.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 3/28/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/// A selection handler that always disallow selection and highlighting.
public struct UnselectableSelectionHandler<ItemType, CellType: ReusableCell> : DataSourceSelectionHandler {

    /// Creates new instance.
    public init() {
    }

    /**
     Called to see if the cell can be highlighted. It always returns `false`.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.

     - returns: It always returns `false`.
     */
    public func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    /**
     Whether or not to select a cell. It always returns `false`.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.

     - returns: It always returns `false`.
     */

    public func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    /**
     Should the cell be delselected or not. It always returns `false`.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.

     - returns: It always returns `false`.
     */
    public func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}
