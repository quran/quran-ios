//
//  GeneralCollectionView.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/13/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/**
 The GeneralCollectionView protocol unifies the interface of the `UICollectionView` and
 `UITableView` so that similar methods with different names will have the same name now that starts with "ds_" prefix.

 Besides, `CompositeDataSource` has different implementation that allows children data sources to manipulate the `UICollectionView` and/or `UITableView` as if the children data sources are in the same top level first section even if it's in a different section.
 */
@objc public protocol GeneralCollectionView: class {

    /**
     Represents the underlying scroll view. Use this method if you want to get the
     `UICollectionView`/`UITableView` itself. `GeneralCollectionView` is not guarnteed to be `UICollectionView` or
     a `UITableView`, use this property to access the underlying `UICollectionView` or `UITableView`.
     So, if you have for example an instance like the following
     ```
     let generalCollectionView: GeneralCollectionView = <...>

     // Not Recommented, can result crashes if there is a CompositeDataSource.
     let underlyingTableView = generalCollectionView as! UITableView
     ```

     **See also** : `asCollectionView()` and `asTableView()`
     */
    var ds_scrollView: UIScrollView { get }

    // MARK: - Register, dequeue

    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    @objc(ds_registerNib:forCellWithReuseIdentifier:)
    func ds_register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String)

    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    @objc(ds_registerClass:forCellWithReuseIdentifier:)
    func ds_register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String)

    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_dequeueReusableCell(withIdentifier identifier: String, for indexPath: IndexPath) -> ReusableCell

    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_dequeueReusableSupplementaryView(ofKind kind: String, withIdentifier identifier: String, for indexPath: IndexPath) -> ReusableSupplementaryView

    // MARK: - Numbers

    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_numberOfSections() -> Int
    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_numberOfItems(inSection section: Int) -> Int

    // MARK: - Manpulate items and sections

    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_reloadData()
    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)?)

    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_insertSections(_ sections: IndexSet, with animation: UITableView.RowAnimation)
    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_deleteSections(_ sections: IndexSet, with animation: UITableView.RowAnimation)
    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_reloadSections(_ sections: IndexSet, with animation: UITableView.RowAnimation)
    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_moveSection(_ section: Int, toSection newSection: Int)

    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_insertItems(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation)
    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_deleteItems(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation)
    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_reloadItems(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation)
    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath)

    // MARK: - Scroll

    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_scrollToItem(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, animated: Bool)

    // MARK: - Select/Deselect

    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionView.ScrollPosition)
    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_deselectItem(at indexPath: IndexPath, animated: Bool)

    // MARK: - IndexPaths, Cells

    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_indexPath(for cell: ReusableCell) -> IndexPath?
    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_indexPathForItem(at point: CGPoint) -> IndexPath?
    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_indexPathsForVisibleItems() -> [IndexPath]
    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_indexPathsForSelectedItems() -> [IndexPath]

    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_visibleCells() -> [ReusableCell]
    /**
     Check documentation of the corresponding methods from `UICollectionView` and `UITableView`.
     */
    func ds_cellForItem(at indexPath: IndexPath) -> ReusableCell?

    // MARK: - Local, Global

    /**
     Converts an index path value relative to the composite data source to an index path value relative to a specific data source.

     - parameter indexPath:    The index path relative to the compsite data source.

     - returns: The global index path relative to the composite data source.
     */
    func ds_localIndexPathForGlobalIndexPath(_ globalIndex: IndexPath) -> IndexPath

    /**
     Converts an index path value relative to a specific data source to an index path value relative to the composite data source.

     - parameter indexPath:     The local index path relative to the passed data source.

     - returns: The global index path relative to the composite data source.
     */
    func ds_globalIndexPathForLocalIndexPath(_ localIndex: IndexPath) -> IndexPath

    /**
     Converts a section value relative to a specific data source to a section value relative to the composite data source.

     - parameter section:       The local section relative to the passed data source.

     - returns: The global section relative to the composite data source.
     */
    func ds_globalSectionForLocalSection(_ localSection: Int) -> Int

}

extension GeneralCollectionView {

    /// Converts global index paths to local index paths.
    ///
    /// - Parameter globalIndexPaths: The array of global index paths.
    /// - Returns: The converted global index paths.
    public func ds_localIndexPathsForGlobalIndexPaths(_ globalIndexPaths: [IndexPath]) -> [IndexPath] {
        return globalIndexPaths.map { ds_localIndexPathForGlobalIndexPath($0) }
    }

    /// Converts local index paths to global index paths.
    ///
    /// - Parameter localIndexPaths: The array of local index paths.
    /// - Returns: The converted local index paths.
    public func ds_globalIndexPathsForLocalIndexPaths(_ localIndexPaths: [IndexPath]) -> [IndexPath] {
        return localIndexPaths.map {  ds_globalIndexPathForLocalIndexPath($0) }
    }

    /// Converts a set of local sections to global sections
    ///
    /// - Parameter localSections: The local sections.
    /// - Returns: The converted global sections.
    public func ds_globalSectionSetForLocalSectionSet(_ localSections: IndexSet) -> IndexSet {
        let globalSections = NSMutableIndexSet()
        for section in localSections {
            let globalSection = ds_globalSectionForLocalSection(section)
            globalSections.add(globalSection)
        }
        return globalSections as IndexSet
    }
}

extension GeneralCollectionView {

    /// Gets the size of the underlying `UITableView` or the `UICollectionView`.
    public var size: CGSize {
        return ds_scrollView.frame.size
    }
}

extension GeneralCollectionView {

    /**
     Represents the underlying `UICollectionView` itself. `GeneralCollectionView` is not guarnteed to be `UICollectionView` or
     a `UITableView`, use this property to access the underlying `UICollectionView` or nil if it is `UITableView`.
     So, if you have for example an instance like the following
     ```
     let generalCollectionView: GeneralCollectionView = <...>

     // Not Recommented, can result crashes if there is a CompositeDataSource.
     let underlyingTableView = generalCollectionView as! UITableView
     ```

     **See also** : `ds_scrollView` and `asTableView()`
     */
    public func asCollectionView() -> UICollectionView? {
        return ds_scrollView as? UICollectionView
    }

    /**
     Represents the underlying `UITableView` itself. `GeneralCollectionView` is not guarnteed to be `UITableView` or
     a `UICollectionView`, use this property to access the underlying `UITableView` or nil if it is `UICollectionView`.
     So, if you have for example an instance like the following
     ```
     let generalCollectionView: GeneralCollectionView = <...>

     // Not Recommented, can result crashes if there is a CompositeDataSource.
     let underlyingTableView = generalCollectionView as! UITableView
     ```

     **See also** : `ds_scrollView` and `asCollectionView()`
     */
    public func asTableView() -> UITableView? {
        return ds_scrollView as? UITableView
    }
}
