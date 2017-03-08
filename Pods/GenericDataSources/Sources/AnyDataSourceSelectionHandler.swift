//
//  AnyDataSourceSelectionHandler.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/14/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/**
 *  Type-erasure for `DataSourceSelectionHandler`.
 */
public struct AnyDataSourceSelectionHandler<ItemType, CellType: ReusableCell> : DataSourceSelectionHandler {

    private let itemsChanged: (BasicDataSource<ItemType, CellType>) -> Void
    private let configureCell: (BasicDataSource<ItemType, CellType>, GeneralCollectionView, CellType, ItemType, IndexPath) -> Void

    private let shouldHighlight: (BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Bool
    private let didHighlight: (BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Void
    private let didUnhighlight: (BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Void

    private let shouldSelect: (BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Bool
    private let didSelect: (BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Void

    private let shouldDeselect: (BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Bool
    private let didDeselect: (BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Void

    /**
     Create new type-erasure that wraps the passed handler.

     - parameter selectionHandler: The handler to pass to the type erasure.

     */
    public init<C: DataSourceSelectionHandler>(_ selectionHandler: C) where C.ItemType == ItemType, C.CellType == CellType {

        itemsChanged = selectionHandler.dataSourceItemsModified
        configureCell = selectionHandler.dataSource(_:collectionView:configure:with:at:)

        shouldHighlight = selectionHandler.dataSource(_:collectionView:shouldHighlightItemAt:)
        didHighlight = selectionHandler.dataSource(_:collectionView:didHighlightItemAt:)
        didUnhighlight = selectionHandler.dataSource(_:collectionView:didUnhighlightItemAt:)

        shouldSelect = selectionHandler.dataSource(_:collectionView:shouldSelectItemAt:)
        didSelect = selectionHandler.dataSource(_:collectionView:didSelectItemAt:)

        shouldDeselect = selectionHandler.dataSource(_:collectionView:shouldDeselectItemAt:)
        didDeselect = selectionHandler.dataSource(_:collectionView:didDeselectItemAt:)
    }

    /**
     Delegating to the unerlying selection handler.
     */
    public func dataSourceItemsModified(_ dataSource: BasicDataSource<ItemType, CellType>) {
        return itemsChanged(dataSource)
    }

    /**
     Delegating to the unerlying selection handler.
     */
    public func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        configure cell: CellType,
        with item: ItemType,
        at indexPath: IndexPath) {
            return configureCell(dataSource, collectionView, cell, item, indexPath)
    }

    /**
     Delegating to the unerlying selection handler.
     */
    public func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldHighlightItemAt indexPath: IndexPath) -> Bool {
            return shouldHighlight(dataSource, collectionView, indexPath)
    }

    /**
     Delegating to the unerlying selection handler.
     */
    public func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didHighlightItemAt indexPath: IndexPath) {
            return didHighlight(dataSource, collectionView, indexPath)
    }

    /**
     Delegating to the unerlying selection handler.
     */
    public func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didUnhighlightItemAt indexPath: IndexPath) {
            return didUnhighlight(dataSource, collectionView, indexPath)
    }

    // MARK: - Selecting

    /**
     Delegating to the unerlying selection handler.
     */
    public func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldSelectItemAt indexPath: IndexPath) -> Bool {
            return shouldSelect(dataSource, collectionView, indexPath)
    }

    /**
     Delegating to the unerlying selection handler.
     */
    public func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didSelectItemAt indexPath: IndexPath) {
            return didSelect(dataSource, collectionView, indexPath)
    }

    // MARK: - Deselecting

    /**
     Delegating to the unerlying selection handler.
     */
    public func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldDeselectItemAt indexPath: IndexPath) -> Bool {
            return shouldDeselect(dataSource, collectionView, indexPath)
    }

    /**
     Delegating to the unerlying selection handler.
     */
    public func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didDeselectItemAt indexPath: IndexPath) {
            return didDeselect(dataSource, collectionView, indexPath)
    }
}

extension DataSourceSelectionHandler {

    /// Converts the selection handler to a type-erased selection handler.
    ///
    /// - Returns: The type-erased selection handler.
    public func anyDataSourceSelectionHandler() -> AnyDataSourceSelectionHandler<ItemType, CellType> {
        return AnyDataSourceSelectionHandler(self)
    }
}
