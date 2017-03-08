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
    open var ds_scrollView: UIScrollView { return self }

    /**
     Just calls the corresponding method `registerNib(nib, forCellReuseIdentifier: identifier)`.
     */
    open func ds_register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        register(nib, forCellReuseIdentifier: identifier)
    }

    /**
     Just calls the corresponding method `registerClass(cellClass, forCellReuseIdentifier: identifier)`.
     */
    open func ds_register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        register(cellClass, forCellReuseIdentifier: identifier)
    }

    /**
     Just calls the corresponding method `reloadData`.
     */
    open func ds_reloadData() {
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
    open func ds_performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
        internal_performBatchUpdates(updates, completion: completion)
    }

    /**
     Just calls the corresponding method `insertSections(sections, with: animation)`.
     */
    open func ds_insertSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        insertSections(sections, with: animation)
    }

    /**
     Just calls the corresponding method `deleteSections(sections, with: animation)`.
     */
    open func ds_deleteSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        deleteSections(sections, with: animation)
    }

    /**
     Just calls the corresponding method `reloadSections(sections, with: animation)`.
     */
    open func ds_reloadSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        reloadSections(sections, with: animation)
    }

    /**
     Just calls the corresponding method `moveSection(section, toSection: newSection)`.
     */
    open func ds_moveSection(_ section: Int, toSection newSection: Int) {
        moveSection(section, toSection: newSection)
    }

    /**
     Just calls the corresponding method `insertRowsAtIndexPaths(indexPaths, with: animation)`.
     */
    open func ds_insertItems(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        insertRows(at: indexPaths, with: animation)
    }

    /**
     Just calls the corresponding method `deleteRowsAtIndexPaths(indexPaths, with: animation)`.
     */
    open func ds_deleteItems(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        deleteRows(at: indexPaths, with: animation)
    }

    /**
     Just calls the corresponding method `reloadRowsAtIndexPaths(indexPaths, with: animation)`.
     */
    open func ds_reloadItems(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        reloadRows(at: indexPaths, with: animation)
    }

    /**
     Just calls the corresponding method `moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)`.
     */
    open func ds_moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        moveRow(at: indexPath, to: newIndexPath)
    }

    /**
     Just calls the corresponding method `scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition(scrollPosition: scrollPosition), animated: animated)`.
     */
    open func ds_scrollToItem(at indexPath: IndexPath, at scrollPosition: UICollectionViewScrollPosition, animated: Bool) {
        scrollToRow(at: indexPath, at: UITableViewScrollPosition(scrollPosition: scrollPosition), animated: animated)
    }

    /**
     Just calls the corresponding method `selectRowAtIndexPath(indexPath, animated: animated, scrollPosition: UITableViewScrollPosition(scrollPosition: scrollPosition))`.
     */
    open func ds_selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionViewScrollPosition) {
        selectRow(at: indexPath, animated: animated, scrollPosition: UITableViewScrollPosition(scrollPosition: scrollPosition))
    }

    /**
     Just calls the corresponding method `deselectRowAtIndexPath(indexPath, animated: animated)`.
     */
    open func ds_deselectItem(at indexPath: IndexPath, animated: Bool) {
        deselectRow(at: indexPath, animated: animated)
    }

    /**
     Just calls the corresponding method `dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)`.
     */
    open func ds_dequeueReusableCell(withIdentifier identifier: String, for indexPath: IndexPath) -> ReusableCell {
        return dequeueReusableCell(withIdentifier: identifier, for: indexPath)
    }

    /// Just calls the corresponding method `dequeueReusableHeaderFooterView(withIdentifier: identifier)`.
    open func ds_dequeueReusableSupplementaryView(ofKind kind: String, withIdentifier identifier: String, for indexPath: IndexPath) -> ReusableSupplementaryView {
        let view = dequeueReusableHeaderFooterView(withIdentifier: identifier)
        let castedView: UITableViewHeaderFooterView = cast(view, message: "UITableView doesn't have a UIHeaderFooterView for reuse identifier '\(identifier)'")
        return castedView
    }

    /**
     Just calls the corresponding method `return numberOfSections`.
     */
    open func ds_numberOfSections() -> Int {
        return numberOfSections
    }

    /**
     Just calls the corresponding method `return numberOfRowsInSection(section)`.
     */
    open func ds_numberOfItems(inSection section: Int) -> Int {
        return numberOfRows(inSection: section)
    }

    /**
     Just calls the corresponding method `return indexPathForCell(cell)`.
     */
    open func ds_indexPath(for reusableCell: ReusableCell) -> IndexPath? {
        let cell: UITableViewCell = cast(reusableCell, message: "Cell '\(reusableCell)' should be of type UITableViewCell.")
        return indexPath(for: cell)
    }

    /**
     Just calls the corresponding method `return indexPathForRowAtPoint(point)`.
     */
    open func ds_indexPathForItem(at point: CGPoint) -> IndexPath? {
        return indexPathForRow(at: point)
    }

    /**
     Just calls the corresponding method `return cellForRowAtIndexPath(indexPath)`.
     */
    open func ds_cellForItem(at indexPath: IndexPath) -> ReusableCell? {
        return cellForRow(at: indexPath)
    }

    /**
     Just calls the corresponding method `visibleCells`.
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
     Just calls the corresponding method `return indexPathsForVisibleRows ?? []`.
     */
    open func ds_indexPathsForVisibleItems() -> [IndexPath] {
        return indexPathsForVisibleRows ?? []
    }

    /**
     Just calls the corresponding method `return indexPathsForSelectedRows ?? []`.
     */
    open func ds_indexPathsForSelectedItems() -> [IndexPath] {
        return indexPathsForSelectedRows ?? []
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
