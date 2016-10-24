//
//  DelegatedGeneralCollectionView.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 3/20/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import UIKit

protocol GeneralCollectionViewMapping {
    
    func globalSectionForLocalSection(_ localSection: Int) -> Int

    func localIndexPathForGlobalIndexPath(_ globalIndexPath: IndexPath) -> IndexPath
    func globalIndexPathForLocalIndexPath(_ localIndexPath: IndexPath) -> IndexPath
    
    var delegate: GeneralCollectionView? { get }
}

@objc class DelegatedGeneralCollectionView: NSObject, GeneralCollectionView {

    let mapping: GeneralCollectionViewMapping
    
    var delegate: GeneralCollectionView {
        guard let delegate = mapping.delegate else {
            fatalError("Couldn't call \(#function) of \(self) with a nil delegate. This is usually because you didn't set your UITableView/UICollection to ds_reusableViewDelegate for the GenericDataSource.")
        }
        return delegate
    }

    init(mapping: GeneralCollectionViewMapping) {
        self.mapping = mapping
    }
    
    // MARK:- Scroll View
    
    var ds_scrollView: UIScrollView {
        return delegate.ds_scrollView
    }
    
    // MARK:- Register, dequeue

    func ds_register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        delegate.ds_register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    func ds_register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        delegate.ds_register(nib, forCellWithReuseIdentifier: identifier)
    }

    func ds_dequeueReusableCell(withIdentifier identifier: String, for indexPath: IndexPath) -> ReusableCell {
        let globalIndexPath = ds_globalIndexPathForLocalIndexPath(indexPath)
        return delegate.ds_dequeueReusableCell(withIdentifier: identifier, for: globalIndexPath)
    }

    // MARK:- Numbers
    
    func ds_numberOfSections() -> Int {
        return delegate.ds_numberOfSections()
    }
    
    func ds_numberOfItems(inSection section: Int) -> Int {
        let globalSection = ds_globalSectionForLocalSection(section)
        return delegate.ds_numberOfItems(inSection: globalSection)
    }
    
    // MARK:- Manpulate items and sections
    
    func ds_reloadData() {
        delegate.ds_reloadData()
    }
    
    func ds_performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
        delegate.ds_performBatchUpdates(updates, completion: completion)
    }
    
    func ds_insertSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        let globalSections = ds_globalSectionSetForLocalSectionSet(sections)
        delegate.ds_insertSections(globalSections, with: animation)
    }
    
    func ds_deleteSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        let globalSections = ds_globalSectionSetForLocalSectionSet(sections)
        delegate.ds_deleteSections(globalSections, with: animation)
    }
    
    func ds_reloadSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        let globalSections = ds_globalSectionSetForLocalSectionSet(sections)
        delegate.ds_reloadSections(globalSections, with: animation)
    }
    
    func ds_moveSection(_ section: Int, toSection newSection: Int) {
        let globalSection = ds_globalSectionForLocalSection(section)
        let globalNewSection = ds_globalSectionForLocalSection(newSection)
        delegate.ds_moveSection(globalSection, toSection: globalNewSection)
    }
    
    func ds_insertItems(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        let globalIndexPaths = ds_globalIndexPathsForLocalIndexPaths(indexPaths)
        delegate.ds_insertItems(at: globalIndexPaths, with: animation)
    }
    
    func ds_deleteItems(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        let globalIndexPaths = ds_globalIndexPathsForLocalIndexPaths(indexPaths)
        delegate.ds_deleteItems(at: globalIndexPaths, with: animation)
    }
    
    func ds_reloadItems(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        let globalIndexPaths = ds_globalIndexPathsForLocalIndexPaths(indexPaths)
        delegate.ds_reloadItems(at: globalIndexPaths, with: animation)
    }

    func ds_moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        let globalIndexPath = ds_globalIndexPathForLocalIndexPath(indexPath)
        let globalNewIndexPath = ds_globalIndexPathForLocalIndexPath(newIndexPath)

        delegate.ds_moveItem(at: globalIndexPath, to: globalNewIndexPath)
    }
    
    // MARK:- Scroll
    
    func ds_scrollToItem(at indexPath: IndexPath, at scrollPosition: UICollectionViewScrollPosition, animated: Bool) {
        let globalIndexPath = ds_globalIndexPathForLocalIndexPath(indexPath)
        delegate.ds_scrollToItem(at: globalIndexPath, at: scrollPosition, animated: animated)
    }

    // MARK:- Select/Deselect
    
    func ds_selectItem(at indexPath: IndexPath?, animated: Bool, scrollPosition: UICollectionViewScrollPosition) {

        let globalIndexPath: IndexPath?
        if let indexPath = indexPath {
            globalIndexPath = ds_globalIndexPathForLocalIndexPath(indexPath)
        } else {
            globalIndexPath = nil
        }
        
        delegate.ds_selectItem(at: globalIndexPath, animated: animated, scrollPosition: scrollPosition)
    }
    
    func ds_deselectItem(at indexPath: IndexPath, animated: Bool) {
        let globalIndexPath = ds_globalIndexPathForLocalIndexPath(indexPath)
        delegate.ds_deselectItem(at: globalIndexPath, animated: animated)
    }
    
    // MARK:- IndexPaths, Cells
    
    func ds_indexPath(for cell: ReusableCell) -> IndexPath? {
        if let indexPath = delegate.ds_indexPath(for: cell) {
            return ds_localIndexPathForGlobalIndexPath(indexPath)
        }
        return nil
    }
    
    func ds_indexPathForItem(at point: CGPoint) -> IndexPath? {
        if let indexPath = delegate.ds_indexPathForItem(at: point) {
            return ds_localIndexPathForGlobalIndexPath(indexPath)
        }
        return nil
    }
    
    func ds_indexPathsForVisibleItems() -> [IndexPath] {
        let indexPaths = delegate.ds_indexPathsForVisibleItems()
        return ds_localIndexPathsForGlobalIndexPaths(indexPaths)
    }
    
    func ds_indexPathsForSelectedItems() -> [IndexPath] {
        let indexPaths = delegate.ds_indexPathsForSelectedItems()
        return ds_localIndexPathsForGlobalIndexPaths(indexPaths)
    }

    func ds_visibleCells() -> [ReusableCell] {
        return delegate.ds_visibleCells()
    }
    
    func ds_cellForItem(at indexPath: IndexPath) -> ReusableCell? {
        let globalIndexPath = ds_globalIndexPathForLocalIndexPath(indexPath)
        return delegate.ds_cellForItem(at: globalIndexPath)
    }

    // MARK: - Local, Global

    func ds_localIndexPathForGlobalIndexPath(_ globalIndexPath: IndexPath) -> IndexPath {
        return mapping.localIndexPathForGlobalIndexPath(globalIndexPath)
    }

    func ds_globalIndexPathForLocalIndexPath(_ localIndexPath: IndexPath) -> IndexPath {
        return mapping.globalIndexPathForLocalIndexPath(localIndexPath)
    }

    func ds_globalSectionForLocalSection(_ localSection: Int) -> Int {
        return mapping.globalSectionForLocalSection(localSection)
    }
}
