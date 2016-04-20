//
//  DataSourceSelectionHandler.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/14/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

public protocol DataSourceSelectionHandler {

    associatedtype ItemType
    associatedtype CellType: ReusableCell

    func dataSourceItemsModified(dataSource: BasicDataSource<ItemType, CellType>)

    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        configureCell cell: CellType,
        withItem item: ItemType,
        atIndexPath indexPath: NSIndexPath)

    // MARK:- Highlighting
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool
    
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didHighlightItemAtIndexPath indexPath: NSIndexPath)
    
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didUnhighlightItemAtIndexPath indexPath: NSIndexPath)
    
    // MARK:- Selecting
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool
    
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath)
    
    // MARK:- Deselecting
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool
    
    func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didDeselectItemAtIndexPath indexPath: NSIndexPath)
}

// MARK:- Default implementation
extension DataSourceSelectionHandler {

    public func dataSourceItemsModified(dataSource: BasicDataSource<ItemType, CellType>) {
    }

    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        configureCell cell: CellType,
        withItem item: ItemType,
        atIndexPath indexPath: NSIndexPath) {
    }
    
    // MARK:- Highlighting
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
            return true
    }
    
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didHighlightItemAtIndexPath indexPath: NSIndexPath) {
            // does nothing
    }
    
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
            // does nothing
    }
    
    // MARK:- Selecting
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
            return true
    }

    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath) {
            // does nothing
    }

    // MARK:- Deselecting
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
            return true
    }
    
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didDeselectItemAtIndexPath indexPath: NSIndexPath) {
            // does nothing
    }
}