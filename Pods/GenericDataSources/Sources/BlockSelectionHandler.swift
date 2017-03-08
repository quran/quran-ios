//
//  BlockSelectionHandler.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 3/28/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/**
 A closure/block-based selection handler when a UITableView/UICollectionView selection changes it will handle it.

 It's mainly used with `BasicDataSource`. It also can work with `BasicDataSource` nested inside multiple `CompositeDataSource`. You can have one handler for each data source.
 */
open class BlockSelectionHandler<ItemType, CellType: ReusableCell> : DataSourceSelectionHandler {

    /// Whether to always allow highlighting or not. This variable used when `shouldHighlightBlock` is nil.
    open var defaultShouldHighlight: Bool = true
    /// Whether to always allow selection or not. This variable used when `shouldSelectBlock` is nil.
    open var defaultShouldSelect: Bool = true
    /// Whether to always allow deselection or not. This variable used when `shouldDeselectBlock` is nil.
    open var defaultShouldDeselect: Bool = true

    /// The items modified closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    open var itemsModifiedBlock: ((BasicDataSource<ItemType, CellType>) -> Void)?
    /// The configure closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    open var configureBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, CellType, ItemType, IndexPath) -> Void)?
    /// The should highlight closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    open var shouldHighlightBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Bool)?
    /// The did highlight closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    open var didHighlightBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Void)?
    /// The did unhighlight closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    open var didUnhighlightBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Void)?
    /// The should select closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    open var shouldSelectBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Bool)?
    /// The did select closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    open var didSelectBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Void)?
    /// The should deselect closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    open var shouldDeselectBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Bool)?
    /// The did deselect closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    open var didDeselectBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, IndexPath) -> Void)?

    /**
     Creates new instance. Default initializer.
     */
    public init() {
    }

    /**
     Called when the items of the data source are modified inserted/delete/updated.
     */
    open func dataSourceItemsModified(_ dataSource: BasicDataSource<ItemType, CellType>) {
        itemsModifiedBlock?(dataSource)
    }

    /**
     Called when the cell needs to be configured.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter cell:           The cell under configuration.
     - parameter item:           The item that will be binded to the cell.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    open func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        configure cell: CellType,
        with item: ItemType,
        at indexPath: IndexPath) {
        configureBlock?(dataSource, collectionView, cell, item, indexPath)
    }

    // MARK: - Highlighting

    /**
     Called to see if the cell can be highlighted.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.

     - returns: `true`, if can be highlighted.
     */
    open func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return shouldHighlightBlock?(dataSource, collectionView, indexPath) ?? defaultShouldHighlight
    }

    /**
     Called when the cell is already highlighted.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    open func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didHighlightItemAt indexPath: IndexPath) {
        didHighlightBlock?(dataSource, collectionView, indexPath)
    }

    /**
     Called after the cell is unhighlighted.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    open func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didUnhighlightItemAt indexPath: IndexPath) {
        didUnhighlightBlock?(dataSource, collectionView, indexPath)
    }

    // MARK: - Selecting

    /**
     Whether or not to select a cell.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.

     - returns: `true`, if should select the item.
     */
    open func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return shouldSelectBlock?(dataSource, collectionView, indexPath) ?? defaultShouldSelect
    }

    /**
     Called when the select is selected.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    open func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didSelectItemAt indexPath: IndexPath) {
        didSelectBlock?(dataSource, collectionView, indexPath)
    }

    // MARK: - Deselecting

    /**
     Should the cell be delselected or not.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.

     - returns: `true`, if the cell should be deleselected.
     */
    open func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return shouldDeselectBlock?(dataSource, collectionView, indexPath) ?? defaultShouldDeselect
    }

    /**
     The cell is already deselected.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    open func dataSource(
        _ dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didDeselectItemAt indexPath: IndexPath) {
        didDeselectBlock?(dataSource, collectionView, indexPath)
    }
}
