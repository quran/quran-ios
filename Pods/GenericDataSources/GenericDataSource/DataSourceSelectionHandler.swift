//
//  DataSourceSelectionHandler.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/14/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/**
 Represents the selection handler when a selection changes it handle it.
 
 It's mainly used with `BasicDataSource`. It also can work with `BasicDataSource` nested inside multiple `CompositeDataSource`. You can have one handler for each data source.
 */
public protocol DataSourceSelectionHandler {

    /**
     Represents the item type
     */
    associatedtype ItemType
    /**
     Represents the cell type
     */
    associatedtype CellType: ReusableCell

    /**
     Called when the items of the data source are modified inserted/delete/updated.
     */
    func dataSourceItemsModified(dataSource: BasicDataSource<ItemType, CellType>)

    /**
     Called when the cell needs to be configured.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter cell:           The cell under configuration.
     - parameter item:           The item that will be binded to the cell.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        configureCell cell: CellType,
        withItem item: ItemType,
        atIndexPath indexPath: NSIndexPath)

    // MARK:- Highlighting

    /**
     Called to see if the cell can be highlighted.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.

     - returns: `true`, if can be highlighted.
     */
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool

    /**
     Called when the cell is already highlighted.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didHighlightItemAtIndexPath indexPath: NSIndexPath)

    /**
     Called after the cell is unhighlighted.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didUnhighlightItemAtIndexPath indexPath: NSIndexPath)
    
    // MARK:- Selecting

    /**
     Whether or not to select a cell.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.

     - returns: `true`, if should select the item.
     */
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool

    /**
     Called when the select is selected.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath)
    
    // MARK:- Deselecting

    /**
     Should the cell be delselected or not.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.

     - returns: `true`, if the cell should be deleselected.
     */
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool

    /**
     The cell is already deselected.

     - parameter dataSource:     The data source that handle the event.
     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The local index path of the cell that will be configured.
     */
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didDeselectItemAtIndexPath indexPath: NSIndexPath)
}

// MARK:- Default implementation
extension DataSourceSelectionHandler {

    /**
     Default implementation. Does nothing.
     */
    public func dataSourceItemsModified(dataSource: BasicDataSource<ItemType, CellType>) {
    }

    /**
     Default implementation. Does nothing.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        configureCell cell: CellType,
        withItem item: ItemType,
        atIndexPath indexPath: NSIndexPath) {
    }
    
    // MARK:- Highlighting

    /**
     Default implementation. Returns `true`.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
            return true
    }

    /**
     Default implementation. Does nothing.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didHighlightItemAtIndexPath indexPath: NSIndexPath) {
            // does nothing
    }

    /**
     Default implementation. Does nothing.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
            // does nothing
    }
    
    // MARK:- Selecting

    /**
     Default implementation. Returns `true`.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
            return true
    }

    /**
     Default implementation. Does nothing.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath) {
            // does nothing
    }

    // MARK:- Deselecting

    /**
     Default implementation. Returns `true`.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
            return true
    }

    /**
     Default implementation. Does nothing.
     */
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didDeselectItemAtIndexPath indexPath: NSIndexPath) {
            // does nothing
    }
}