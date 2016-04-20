//
//  BlockSelectionHandler.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 3/28/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

public class BlockSelectionHandler<ItemType, CellType: ReusableCell> : DataSourceSelectionHandler {

    public var defaultShouldHighlight: Bool = true
    public var defaultShouldSelect: Bool = true
    public var defaultShouldDeselect: Bool = true
    
    public var itemsModifiedBlock: (BasicDataSource<ItemType, CellType> -> Void)?
    public var configureBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, CellType, ItemType, NSIndexPath) -> Void)?
    public var shouldHighlightBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Bool)?
    public var didHighlightBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Void)?
    public var didUnhighlightBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Void)?
    public var shouldSelectBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Bool)?
    public var didSelectBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Void)?
    public var shouldDeselectBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Bool)?
    public var didDeselectBlock: ((BasicDataSource<ItemType, CellType>, GeneralCollectionView, NSIndexPath) -> Void)?
    
    public init() {
    }

    public func dataSourceItemsModified(dataSource: BasicDataSource<ItemType, CellType>) {
        itemsModifiedBlock?(dataSource)
    }
    
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        configureCell cell: CellType,
                      withItem item: ItemType,
                               atIndexPath indexPath: NSIndexPath) {
        configureBlock?(dataSource, collectionView, cell, item, indexPath)
    }
    
    // MARK:- Highlighting
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return shouldHighlightBlock?(dataSource, collectionView, indexPath) ?? defaultShouldHighlight
    }

    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        didHighlightBlock?(dataSource, collectionView, indexPath)
    }

    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        didUnhighlightBlock?(dataSource, collectionView, indexPath)
    }
    
    // MARK:- Selecting
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return shouldSelectBlock?(dataSource, collectionView, indexPath) ?? defaultShouldSelect
    }

    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath) {
        didSelectBlock?(dataSource, collectionView, indexPath)
    }
    
    // MARK:- Deselecting
    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return shouldDeselectBlock?(dataSource, collectionView, indexPath) ?? defaultShouldDeselect
    }

    public func dataSource(
        dataSource: BasicDataSource<ItemType, CellType>,
        collectionView: GeneralCollectionView,
        didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        didDeselectBlock?(dataSource, collectionView, indexPath)
    }
}