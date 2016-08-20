//
//  DataSource.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/13/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/**
 The DataSource protocol is a general data source and delegate protocol for both a UITableViewDataSource/UITableViewDelegate and UICollectionViewDataSource/UICollectionViewDelegate and adopted by an object that mediates the application’s data model for a view object (e.g. `UITableView` or `UICollectionView`.
 */
@objc public protocol DataSource : class {

    /**
     Whether the data source provides the item size/height delegate calls for `tableView:heightForRowAtIndexPath:`
     or `collectionView:layout:sizeForItemAtIndexPath:` or not.
     
     - returns: `true`, if the data source object will consume the delegate calls.
        `false` if the size/height information is provided to the `UITableView` using `rowHeight` and/or `estimatedRowHeight`
        or to the `UICollectionViewFlowLayout` using `itemSize` and/or `estimatedItemSize`.
     */
    func ds_shouldConsumeItemSizeDelegateCalls() -> Bool

    /** 
     The resuable view delegate. Usually it is the UICollectionView/UITableView.
     This is provided in case a data source implementation would like to query or modify something in the view (e.g. inserting a section, etc.)
     */
    weak var ds_reusableViewDelegate: GeneralCollectionView? { get set }

    /**
     Asks the data source to return the number of sections.

     - returns: The number of sections.
     */
    func ds_numberOfSections() -> Int
    
    /**
     Asks the data source to return the number of items in a given section.
     
     - parameter section: An index number identifying a section.

     - returns: The number of items in a given section
     */
    func ds_numberOfItems(inSection section: Int) -> Int
    
    /**
     Asks the data source for a cell to insert in a particular location of the general collection view.
     
     - parameter collectionView: A general collection view object requesting the cell.
     - parameter indexPath:      An index path locating an item in the view.
     
     - returns: An object conforming to ReusableCell that the view can use for the specified item.
     */
    func ds_collectionView(collectionView: GeneralCollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> ReusableCell

    /**
     Asks the data source for the size of a cell in a particular location of the general collection view.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     
     - returns: The size of the cell in a given location. For `UITableView`, the width is ignored.
     */
    optional func ds_collectionView(collectionView: GeneralCollectionView, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize

    // MARK:- Selection

    /**
     Asks the delegate if the specified item should be highlighted.
     `true` if the item should be highlighted or `false` if it should not.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     
     - returns: `true` if the item should be highlighted or `false` if it should not.
     */
    func ds_collectionView(collectionView: GeneralCollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool
    
    /**
     Tells the delegate that the specified item was highlighted.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    func ds_collectionView(collectionView: GeneralCollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath)
    
    /**
     Tells the delegate that the highlight was removed from the item at the specified index path.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    func ds_collectionView(collectionView: GeneralCollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath)
    
    /**
     Asks the delegate if the specified item should be selected.
     `true` if the item should be selected or `false` if it should not.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     
     - returns: `true` if the item should be selected or `false` if it should not.
     */
    func ds_collectionView(collectionView: GeneralCollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool
    
    /**
     Tells the delegate that the specified item was selected.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    func ds_collectionView(collectionView: GeneralCollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    
    /**
     Asks the delegate if the specified item should be deselected.
     `true` if the item should be deselected or `false` if it should not.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     
     - returns: `true` if the item should be deselected or `false` if it should not.
     */
    func ds_collectionView(collectionView: GeneralCollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool

    /**
     Tells the delegate that the specified item was deselected.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    func ds_collectionView(collectionView: GeneralCollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
}