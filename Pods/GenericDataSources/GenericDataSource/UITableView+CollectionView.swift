//
//  UITableView+CollectionView.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 4/11/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

extension UITableView: GeneralCollectionView {
    
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
     Just calls the corresponding method `registerNib(nib, forCellReuseIdentifier: identifier)`.
     */
    public func ds_registerNib(nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        registerNib(nib, forCellReuseIdentifier: identifier)
    }

    /**
     Just calls the corresponding method `registerClass(cellClass, forCellReuseIdentifier: identifier)`.
     */
    public func ds_registerClass(cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        registerClass(cellClass, forCellReuseIdentifier: identifier)
    }
    
    /**
     Just calls the corresponding method `reloadData`.
     */
    public func ds_reloadData() {
        reloadData()
    }
    
    /**
     It does the following
     ```
     beginUpdates()
     updates?()
     endUpdates()
     completion?(false)
     ```
     */
    public func ds_performBatchUpdates(updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
        internal_performBatchUpdates(updates, completion: completion)
    }
    
    /**
     Just calls the corresponding method `insertSections(sections, withRowAnimation: animation)`.
     */
    public func ds_insertSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        insertSections(sections, withRowAnimation: animation)
    }
    
    /**
     Just calls the corresponding method `deleteSections(sections, withRowAnimation: animation)`.
     */
    public func ds_deleteSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        deleteSections(sections, withRowAnimation: animation)
    }
    
    /**
     Just calls the corresponding method `reloadSections(sections, withRowAnimation: animation)`.
     */
    public func ds_reloadSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        reloadSections(sections, withRowAnimation: animation)
    }
    
    /**
     Just calls the corresponding method `moveSection(section, toSection: newSection)`.
     */
    public func ds_moveSection(section: Int, toSection newSection: Int) {
        moveSection(section, toSection: newSection)
    }

    /**
     Just calls the corresponding method `insertRowsAtIndexPaths(indexPaths, withRowAnimation: animation)`.
     */
    public func ds_insertItemsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        insertRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
    }
    
    /**
     Just calls the corresponding method `deleteRowsAtIndexPaths(indexPaths, withRowAnimation: animation)`.
     */
    public func ds_deleteItemsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        deleteRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
    }
    
    /**
     Just calls the corresponding method `reloadRowsAtIndexPaths(indexPaths, withRowAnimation: animation)`.
     */
    public func ds_reloadItemsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        reloadRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
    }
    
    /**
     Just calls the corresponding method `moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)`.
     */
    public func ds_moveItemAtIndexPath(indexPath: NSIndexPath, toIndexPath newIndexPath: NSIndexPath) {
        moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)
    }
    
    /**
     Just calls the corresponding method `scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition(scrollPosition: scrollPosition), animated: animated)`.
     */
    public func ds_scrollToItemAtIndexPath(indexPath: NSIndexPath, atScrollPosition scrollPosition: UICollectionViewScrollPosition, animated: Bool) {
        scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition(scrollPosition: scrollPosition), animated: animated)
    }
    
    /**
     Just calls the corresponding method `selectRowAtIndexPath(indexPath, animated: animated, scrollPosition: UITableViewScrollPosition(scrollPosition: scrollPosition))`.
     */
    public func ds_selectItemAtIndexPath(indexPath: NSIndexPath?, animated: Bool, scrollPosition: UICollectionViewScrollPosition) {
        selectRowAtIndexPath(indexPath, animated: animated, scrollPosition: UITableViewScrollPosition(scrollPosition: scrollPosition))
    }
    
    /**
     Just calls the corresponding method `deselectRowAtIndexPath(indexPath, animated: animated)`.
     */
    public func ds_deselectItemAtIndexPath(indexPath: NSIndexPath, animated: Bool) {
        deselectRowAtIndexPath(indexPath, animated: animated)
    }
    
    /**
     Just calls the corresponding method `return dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)`.
     */
    public func ds_dequeueReusableCellViewWithIdentifier(identifier: String, forIndexPath indexPath: NSIndexPath) -> ReusableCell {
        return dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)
    }
    
    /**
     Just calls the corresponding method `return numberOfSections`.
     */
    public func ds_numberOfSections() -> Int {
        return numberOfSections
    }
    
    /**
     Just calls the corresponding method `return numberOfRowsInSection(section)`.
     */
    public func ds_numberOfItemsInSection(section: Int) -> Int {
        return numberOfRowsInSection(section)
    }
    
    /**
     Just calls the corresponding method `return indexPathForCell(cell)`.
     */
    public func ds_indexPathForCell(reusableCell: ReusableCell) -> NSIndexPath? {
        guard let cell = reusableCell as? UITableViewCell else {
            fatalError("Cell '\(reusableCell)' should be of type UITableViewCell.")
        }
        return indexPathForCell(cell)
    }
    
    /**
     Just calls the corresponding method `return indexPathForRowAtPoint(point)`.
     */
    public func ds_indexPathForItemAtPoint(point: CGPoint) -> NSIndexPath? {
        return indexPathForRowAtPoint(point)
    }
    
    /**
     Just calls the corresponding method `return cellForRowAtIndexPath(indexPath)`.
     */
    public func ds_cellForItemAtIndexPath(indexPath: NSIndexPath) -> ReusableCell? {
        return cellForRowAtIndexPath(indexPath)
    }
    
    /**
     Just calls the corresponding method `visibleCells`.
     */
    public func ds_visibleCells() -> [ReusableCell] {
        let cells = visibleCells
        var reusableCells = [ReusableCell]()
        for cell in cells {
            reusableCells.append(cell)
        }
        return reusableCells
    }
    
    /**
     Just calls the corresponding method `return indexPathsForVisibleRows ?? []`.
     */
    public func ds_indexPathsForVisibleItems() -> [NSIndexPath] {
        return indexPathsForVisibleRows ?? []
    }
    
    /**
     Just calls the corresponding method `return indexPathsForSelectedRows ?? []`.
     */
    public func ds_indexPathsForSelectedItems() -> [NSIndexPath] {
        return indexPathsForSelectedRows ?? []
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
