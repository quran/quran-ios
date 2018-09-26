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
    open var ds_scrollView: UIScrollView { return self }

    /**
     Just calls the corresponding method `registerNib(nib, forCellWithReuseIdentifier: identifier)`.
     */
    open func ds_register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        register(nib, forCellWithReuseIdentifier: identifier)
    }

    /**
     Just calls the corresponding method `registerClass(cellClass, forCellWithReuseIdentifier: identifier)`.
     */
    open func ds_register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    /**
     Just calls the corresponding method `reloadData()`.
     */
    open func ds_reloadData() {
        reloadData()
    }

    /**
     Just calls the corresponding method `performBatchUpdates(updates, completion: completion)`.
     */
    open func ds_performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
        internal_performBatchUpdates(updates, completion: completion)
    }

    /**
     Just calls the corresponding method `insertSections(sections)`.
     */
    open func ds_insertSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        insertSections(sections)
    }

    /**
     Just calls the corresponding method `deleteSections(sections)`.
     */
    open func ds_deleteSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        deleteSections(sections)
    }

    /**
     Just calls the corresponding method `reloadSections(sections)`.
     */
    open func ds_reloadSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        reloadSections(sections)
    }

    /**
     Just calls the corresponding method `moveSection(section, toSection: newSection)`.
     */
    open func ds_moveSection(_ section: Int, toSection newSection: Int) {
        moveSection(section, toSection: newSection)
    }

    /**
     Just calls the corresponding method `insertItemsAtIndexPaths(indexPaths)`.
     */
    open func ds_insertItems(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        insertItems(at: indexPaths)
    }

    /**
     Just calls the corresponding method `deleteItemsAtIndexPaths(indexPaths)`.
     */
    open func ds_deleteItems(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        deleteItems(at: indexPaths)
    }

    /**
     Just calls the corresponding method `reloadItemsAtIndexPaths(indexPaths)`.
     */
    open func ds_reloadItems(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        reloadItems(at: indexPaths)
    }

    /**
     Just calls the corresponding method `moveItemAt(indexPath, toIndexPath: newIndexPath)`.
     */
    open func ds_moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        moveItem(at: indexPath, to: newIndexPath)
    }

    /**
     Just calls the corresponding method `scrollToItemAt(indexPath, atScrollPosition: scrollPosition, animated: animated)`.
     */
    open func ds_scrollToItem(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
    }

    /**
     Just calls the corresponding method `selectItemAt(indexPath, animated: animated, scrollPosition: scrollPosition)`.
     */
    open func ds_selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionView.ScrollPosition) {
        selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
    }

    /**
     Just calls the corresponding method `deselectItemAt(indexPath, animated: animated)`.
     */
    open func ds_deselectItem(at indexPath: IndexPath, animated: Bool) {
        deselectItem(at: indexPath, animated: animated)
    }

    /**
     Just calls the corresponding method `return dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)`.
     */
    open func ds_dequeueReusableCell(withIdentifier identifier: String, for indexPath: IndexPath) -> ReusableCell {
        return dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    }

    /**
     Just calls the corresponding method `dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath)`.
     */
    open func ds_dequeueReusableSupplementaryView(ofKind kind: String, withIdentifier identifier: String, for indexPath: IndexPath) -> ReusableSupplementaryView {
        return dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath)
    }

    /**
     Just calls the corresponding method `return indexPathForCell(cell)`.
     */
    open func ds_indexPath(for reusableCell: ReusableCell) -> IndexPath? {
        let cell: UICollectionViewCell = cast(reusableCell, message: "Cell '\(reusableCell)' should be of type UICollectionViewCell.")
        return indexPath(for: cell)
    }

    /**
     Just calls the corresponding method `return indexPathForItemAtPoint(point)`.
     */
    open func ds_indexPathForItem(at point: CGPoint) -> IndexPath? {
        return indexPathForItem(at: point)
    }

    /**
     Just calls the corresponding method `return numberOfSections()`.
     */
    open func ds_numberOfSections() -> Int {
        return numberOfSections
    }

    /**
     Just calls the corresponding method `return numberOfItemsInSection(section)`.
     */
    open func ds_numberOfItems(inSection section: Int) -> Int {
        return numberOfItems(inSection: section)
    }

    /**
     Just calls the corresponding method `return cellForItemAt(indexPath)`.
     */
    open func ds_cellForItem(at indexPath: IndexPath) -> ReusableCell? {
        return cellForItem(at: indexPath)
    }

    /**
     Just calls the corresponding method `visibleCells()`.
     */
    open func ds_visibleCells() -> [ReusableCell] {
        let cells = visibleCells
        var reusableCells = [ReusableCell]()
        for cell in cells {
            reusableCells.append(cell)
        }
        return reusableCells
    }

    /**
     Just calls the corresponding method `return indexPathsForVisibleItems()`.
     */
    open func ds_indexPathsForVisibleItems() -> [IndexPath] {
        return indexPathsForVisibleItems
    }

    /**
     Just calls the corresponding method `return indexPathsForSelectedItems() ?? []`.
     */
    open func ds_indexPathsForSelectedItems() -> [IndexPath] {
        return indexPathsForSelectedItems ?? []
    }

    /**
     Always returns the same value passed.
     */
    open func ds_localIndexPathForGlobalIndexPath(_ globalIndex: IndexPath) -> IndexPath {
        return globalIndex
    }

    /**
     Always returns the same value passed.
     */
    open func ds_globalIndexPathForLocalIndexPath(_ localIndex: IndexPath) -> IndexPath {
        return localIndex
    }

    /**
     Always returns the same value passed.
     */
    open func ds_globalSectionForLocalSection(_ localSection: Int) -> Int {
        return localSection
    }
}
