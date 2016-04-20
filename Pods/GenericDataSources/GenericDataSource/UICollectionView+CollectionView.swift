//
//  UICollectionView+CollectionView.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 4/11/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

extension UICollectionView: GeneralCollectionView {
    
    /**
     Represents the underlying scroll view. Use this method if you want to get the
     `UICollectionView`/`UITableView` itself not a wrapper.
     So, if you have for example an instance like the following
     ```
     let generalCollectionView: GeneralCollectionView = <...>
     
     // Not Recommented, can result crashes if there is a CompositeDataSource.
     let underlyingTableView = generalCollectionView as! UITableView
     
     // Recommended, safer
     let underlyingTableView = generalCollectionView.ds_scrollView as! UITableView
     ```
     The later can result a crash if the scroll view is a UICollectionView not a UITableView.
     
     */
    public var ds_scrollView: UIScrollView { return self }
    
    /**
     Just calls the corresponding method `registerNib(nib, forCellWithReuseIdentifier: identifier)`.
     */
    public func ds_registerNib(nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        registerNib(nib, forCellWithReuseIdentifier: identifier)
    }
    
    /**
     Just calls the corresponding method `registerClass(cellClass, forCellWithReuseIdentifier: identifier)`.
     */
    public func ds_registerClass(cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        registerClass(cellClass, forCellWithReuseIdentifier: identifier)
    }
    
    /**
     Just calls the corresponding method `reloadData()`.
     */
    public func ds_reloadData() {
        reloadData()
    }
    
    /**
     Just calls the corresponding method `performBatchUpdates(updates, completion: completion)`.
     */
    public func ds_performBatchUpdates(updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
        internal_performBatchUpdates(updates, completion: completion)
    }
    
    /**
     Just calls the corresponding method `insertSections(sections)`.
     */
    public func ds_insertSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        insertSections(sections)
    }
    
    /**
     Just calls the corresponding method `deleteSections(sections)`.
     */
    public func ds_deleteSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        deleteSections(sections)
    }
    
    /**
     Just calls the corresponding method `reloadSections(sections)`.
     */
    public func ds_reloadSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        reloadSections(sections)
    }
    
    /**
     Just calls the corresponding method `moveSection(section, toSection: newSection)`.
     */
    public func ds_moveSection(section: Int, toSection newSection: Int) {
        moveSection(section, toSection: newSection)
    }
    
    /**
     Just calls the corresponding method `insertItemsAtIndexPaths(indexPaths)`.
     */
    public func ds_insertItemsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        insertItemsAtIndexPaths(indexPaths)
    }
    
    /**
     Just calls the corresponding method `deleteItemsAtIndexPaths(indexPaths)`.
     */
    public func ds_deleteItemsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        deleteItemsAtIndexPaths(indexPaths)
    }
    
    /**
     Just calls the corresponding method `reloadItemsAtIndexPaths(indexPaths)`.
     */
    public func ds_reloadItemsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        reloadItemsAtIndexPaths(indexPaths)
    }
    
    /**
     Just calls the corresponding method `moveItemAtIndexPath(indexPath, toIndexPath: newIndexPath)`.
     */
    public func ds_moveItemAtIndexPath(indexPath: NSIndexPath, toIndexPath newIndexPath: NSIndexPath) {
        moveItemAtIndexPath(indexPath, toIndexPath: newIndexPath)
    }
    
    /**
     Just calls the corresponding method `scrollToItemAtIndexPath(indexPath, atScrollPosition: scrollPosition, animated: animated)`.
     */
    public func ds_scrollToItemAtIndexPath(indexPath: NSIndexPath, atScrollPosition scrollPosition: UICollectionViewScrollPosition, animated: Bool) {
        scrollToItemAtIndexPath(indexPath, atScrollPosition: scrollPosition, animated: animated)
    }
    
    /**
     Just calls the corresponding method `selectItemAtIndexPath(indexPath, animated: animated, scrollPosition: scrollPosition)`.
     */
    public func ds_selectItemAtIndexPath(indexPath: NSIndexPath?, animated: Bool, scrollPosition: UICollectionViewScrollPosition) {
        selectItemAtIndexPath(indexPath, animated: animated, scrollPosition: scrollPosition)
    }
    
    /**
     Just calls the corresponding method `deselectItemAtIndexPath(indexPath, animated: animated)`.
     */
    public func ds_deselectItemAtIndexPath(indexPath: NSIndexPath, animated: Bool) {
        deselectItemAtIndexPath(indexPath, animated: animated)
    }
    
    /**
     Just calls the corresponding method `return dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)`.
     */
    public func ds_dequeueReusableCellViewWithIdentifier(identifier: String, forIndexPath indexPath: NSIndexPath) -> ReusableCell {
        return dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
    }
    
    /**
     Just calls the corresponding method `return indexPathForCell(cell)`.
     */
    public func ds_indexPathForCell(reusableCell: ReusableCell) -> NSIndexPath? {
        guard let cell = reusableCell as? UICollectionViewCell else {
            fatalError("Cell '\(reusableCell)' should be of type UICollectionViewCell.")
        }
        return indexPathForCell(cell)
    }
    
    /**
     Just calls the corresponding method `return indexPathForItemAtPoint(point)`.
     */
    public func ds_indexPathForItemAtPoint(point: CGPoint) -> NSIndexPath? {
        return indexPathForItemAtPoint(point)
    }
    
    /**
     Just calls the corresponding method `return numberOfSections()`.
     */
    public func ds_numberOfSections() -> Int {
        return numberOfSections()
    }
    
    /**
     Just calls the corresponding method `return numberOfItemsInSection(section)`.
     */
    public func ds_numberOfItemsInSection(section: Int) -> Int {
        return numberOfItemsInSection(section)
    }
    
    /**
     Just calls the corresponding method `return cellForItemAtIndexPath(indexPath)`.
     */
    public func ds_cellForItemAtIndexPath(indexPath: NSIndexPath) -> ReusableCell? {
        return cellForItemAtIndexPath(indexPath)
    }
    
    /**
     Just calls the corresponding method `visibleCells()`.
     */
    public func ds_visibleCells() -> [ReusableCell] {
        let cells = visibleCells()
        var reusableCells = [ReusableCell]()
        for cell in cells {
            reusableCells.append(cell)
        }
        return reusableCells
    }
    
    /**
     Just calls the corresponding method `return indexPathsForVisibleItems()`.
     */
    public func ds_indexPathsForVisibleItems() -> [NSIndexPath] {
        return indexPathsForVisibleItems()
    }
    
    /**
     Just calls the corresponding method `return indexPathsForSelectedItems() ?? []`.
     */
    public func ds_indexPathsForSelectedItems() -> [NSIndexPath] {
        return indexPathsForSelectedItems() ?? []
    }
    
    /**
     Always returns the same value passed.
     */
    public func ds_localIndexPathForGlobalIndexPath(globalIndex: NSIndexPath) -> NSIndexPath {
        return globalIndex
    }
    
    /**
     Always returns the same value passed.
     */
    public func ds_globalIndexPathForLocalIndexPath(localIndex: NSIndexPath) -> NSIndexPath {
        return localIndex
    }

    /**
     Always returns the same value passed.
     */
    public func ds_globalSectionForLocalSection(localSection: Int) -> Int {
        return localSection
    }
}
