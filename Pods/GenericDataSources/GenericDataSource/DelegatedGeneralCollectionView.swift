//
//  DelegatedGeneralCollectionView.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 3/20/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import UIKit

protocol GeneralCollectionViewMapping {
    
    func globalSectionForLocalSection(localSection: Int) -> Int

    func localIndexPathForGlobalIndexPath(globalIndexPath: NSIndexPath) -> NSIndexPath
    func globalIndexPathForLocalIndexPath(localIndexPath: NSIndexPath) -> NSIndexPath
    
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
    
    func ds_registerClass(cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        delegate.ds_registerClass(cellClass, forCellWithReuseIdentifier: identifier)
    }
    
    func ds_registerNib(nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        delegate.ds_registerNib(nib, forCellWithReuseIdentifier: identifier)
    }
    
    func ds_dequeueReusableCellViewWithIdentifier(identifier: String, forIndexPath indexPath: NSIndexPath) -> ReusableCell {
        let globalIndexPath = ds_globalIndexPathForLocalIndexPath(indexPath)
        return delegate.ds_dequeueReusableCellViewWithIdentifier(identifier, forIndexPath: globalIndexPath)
    }

    // MARK:- Numbers
    
    func ds_numberOfSections() -> Int {
        return delegate.ds_numberOfSections()
    }
    
    func ds_numberOfItemsInSection(section: Int) -> Int {
        let globalSection = ds_globalSectionForLocalSection(section)
        return delegate.ds_numberOfItemsInSection(globalSection)
    }
    
    // MARK:- Manpulate items and sections
    
    func ds_reloadData() {
        delegate.ds_reloadData()
    }
    
    func ds_performBatchUpdates(updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
        delegate.ds_performBatchUpdates(updates, completion: completion)
    }
    
    func ds_insertSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        let globalSections = ds_globalSectionSetForLocalSectionSet(sections)
        delegate.ds_insertSections(globalSections, withRowAnimation: animation)
    }
    
    func ds_deleteSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        let globalSections = ds_globalSectionSetForLocalSectionSet(sections)
        delegate.ds_deleteSections(globalSections, withRowAnimation: animation)
    }
    
    func ds_reloadSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        let globalSections = ds_globalSectionSetForLocalSectionSet(sections)
        delegate.ds_reloadSections(globalSections, withRowAnimation: animation)
    }
    
    func ds_moveSection(section: Int, toSection newSection: Int) {
        let globalSection = ds_globalSectionForLocalSection(section)
        let globalNewSection = ds_globalSectionForLocalSection(newSection)
        delegate.ds_moveSection(globalSection, toSection: globalNewSection)
    }
    
    func ds_insertItemsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        let globalIndexPaths = ds_globalIndexPathsForLocalIndexPaths(indexPaths)
        delegate.ds_insertItemsAtIndexPaths(globalIndexPaths, withRowAnimation: animation)
    }
    
    func ds_deleteItemsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        let globalIndexPaths = ds_globalIndexPathsForLocalIndexPaths(indexPaths)
        delegate.ds_deleteItemsAtIndexPaths(globalIndexPaths, withRowAnimation: animation)
    }
    
    func ds_reloadItemsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        let globalIndexPaths = ds_globalIndexPathsForLocalIndexPaths(indexPaths)
        delegate.ds_reloadItemsAtIndexPaths(globalIndexPaths, withRowAnimation: animation)
    }
    
    func ds_moveItemAtIndexPath(indexPath: NSIndexPath, toIndexPath newIndexPath: NSIndexPath) {
        let globalIndexPath = ds_globalIndexPathForLocalIndexPath(indexPath)
        let globalNewIndexPath = ds_globalIndexPathForLocalIndexPath(newIndexPath)
        
        delegate.ds_moveItemAtIndexPath(globalIndexPath, toIndexPath: globalNewIndexPath)
    }
    
    // MARK:- Scroll
    
    func ds_scrollToItemAtIndexPath(indexPath: NSIndexPath, atScrollPosition scrollPosition: UICollectionViewScrollPosition, animated: Bool) {
        let globalIndexPath = ds_globalIndexPathForLocalIndexPath(indexPath)
        delegate.ds_scrollToItemAtIndexPath(globalIndexPath, atScrollPosition: scrollPosition, animated: animated)
    }

    // MARK:- Select/Deselect
    
    func ds_selectItemAtIndexPath(indexPath: NSIndexPath?, animated: Bool, scrollPosition: UICollectionViewScrollPosition) {

        let globalIndexPath: NSIndexPath?
        if let indexPath = indexPath {
            globalIndexPath = ds_globalIndexPathForLocalIndexPath(indexPath)
        } else {
            globalIndexPath = nil
        }
        
        delegate.ds_selectItemAtIndexPath(globalIndexPath, animated: animated, scrollPosition: scrollPosition)
    }
    
    func ds_deselectItemAtIndexPath(indexPath: NSIndexPath, animated: Bool) {
        let globalIndexPath = ds_globalIndexPathForLocalIndexPath(indexPath)
        delegate.ds_deselectItemAtIndexPath(globalIndexPath, animated: animated)
    }
    
    // MARK:- IndexPaths, Cells
    
    func ds_indexPathForCell(cell: ReusableCell) -> NSIndexPath? {
        if let indexPath = delegate.ds_indexPathForCell(cell) {
            return ds_localIndexPathForGlobalIndexPath(indexPath)
        }
        return nil
    }
    
    func ds_indexPathForItemAtPoint(point: CGPoint) -> NSIndexPath? {
        if let indexPath = delegate.ds_indexPathForItemAtPoint(point) {
            return ds_localIndexPathForGlobalIndexPath(indexPath)
        }
        return nil
    }
    
    func ds_indexPathsForVisibleItems() -> [NSIndexPath] {
        let indexPaths = delegate.ds_indexPathsForVisibleItems()
        return ds_localIndexPathsForGlobalIndexPaths(indexPaths)
    }
    
    func ds_indexPathsForSelectedItems() -> [NSIndexPath] {
        let indexPaths = delegate.ds_indexPathsForSelectedItems()
        return ds_localIndexPathsForGlobalIndexPaths(indexPaths)
    }

    func ds_visibleCells() -> [ReusableCell] {
        return delegate.ds_visibleCells()
    }
    
    func ds_cellForItemAtIndexPath(indexPath: NSIndexPath) -> ReusableCell? {
        let globalIndexPath = ds_globalIndexPathForLocalIndexPath(indexPath)
        return delegate.ds_cellForItemAtIndexPath(globalIndexPath)
    }

    // MARK: - Local, Global

    func ds_localIndexPathForGlobalIndexPath(globalIndexPath: NSIndexPath) -> NSIndexPath {
        return mapping.localIndexPathForGlobalIndexPath(globalIndexPath)
    }

    func ds_globalIndexPathForLocalIndexPath(localIndexPath: NSIndexPath) -> NSIndexPath {
        return mapping.globalIndexPathForLocalIndexPath(localIndexPath)
    }

    func ds_globalSectionForLocalSection(localSection: Int) -> Int {
        return mapping.globalSectionForLocalSection(localSection)
    }
}
