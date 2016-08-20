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
public class BlockSelectionHandler<ItemType, CellType: ReusableCell> : DataSourceSelectionHandler {

    /// Whether to always allow highlighting or not. This variable used when `shouldHighlightBlock` is nil.
    public var defaultShouldHighlight: Bool = true
    /// Whether to always allow selection or not. This variable used when `shouldSelectBlock` is nil.
    public var defaultShouldSelect: Bool = true
    /// Whether to always allow deselection or not. This variable used when `shouldDeselectBlock` is nil.
    public var defaultShouldDeselect: Bool = true

    /// The items modified closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    public var itemsModifiedBlock: (BasicDataSource<ItemType, CellType> -> Void)?
    /// The configure closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    public var configureBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, CellType, ItemType, NSIndexPath) -> Void)?
    /// The should highlight closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    public var shouldHighlightBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Bool)?
    /// The did highlight closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    public var didHighlightBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Void)?
    /// The did unhighlight closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    public var didUnhighlightBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Void)?
    /// The should select closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    public var shouldSelectBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Bool)?
    /// The did select closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    public var didSelectBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Void)?
    /// The should deselect closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    public var shouldDeselectBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Bool)?
    /// The did deselect closure. Look at its corresponding method in `DataSourceSelectionHandler`.
    public var didDeselectBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Void)?

    /**
     Creates new instance. Default initializer.
     */
    public init() {
    }

    /**
     Called when the items of the data source are modified inserted/delete/updated.
     */
    public func dataSourceItemsModified(dataSource: BasicDataSource<ItemType, CellType>) {
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
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        configureCell cell: CellType,
                      withItem item: ItemType,
                               atIndexPath indexPath: NSIndexPath) {
        configureBlock?(dataSource, collectionView, cell, item, indexPath)
    }
    
    // MARK:- Highlighting

    /**
     Called to see if the cell can be highlighted.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.

     - returns: `true`, if can be highlighted.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return shouldHighlightBlock?(dataSource, collectionView, indexPath) ?? defaultShouldHighlight
    }

    /**
     Called when the cell is already highlighted.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        didHighlightBlock?(dataSource, collectionView, indexPath)
    }

    /**
     Called after the cell is unhighlighted.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        didUnhighlightBlock?(dataSource, collectionView, indexPath)
    }
    
    // MARK:- Selecting

    /**
     Whether or not to select a cell.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.

     - returns: `true`, if should select the item.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return shouldSelectBlock?(dataSource, collectionView, indexPath) ?? defaultShouldSelect
    }

    /**
     Called when the select is selected.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath) {
        didSelectBlock?(dataSource, collectionView, indexPath)
    }
    
    // MARK:- Deselecting

    /**
     Should the cell be delselected or not.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.

     - returns: `true`, if the cell should be deleselected.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return shouldDeselectBlock?(dataSource, collectionView, indexPath) ?? defaultShouldDeselect
    }

    /**
     The cell is already deselected.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        didDeselectBlock?(dataSource, collectionView, indexPath)
    }
}