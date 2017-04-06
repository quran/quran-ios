//
//  SegmentedDataSource.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 11/13/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

open class SegmentedDataSource: AbstractDataSource {

    private var childrenReusableDelegate: _DelegatedGeneralCollectionView!

    /**
     Creates new instance.
     */
    public override init() {
        super.init()
        let mapping = _SegmentedGeneralCollectionViewMapping(parentDataSource: self)
        childrenReusableDelegate = _DelegatedGeneralCollectionView(mapping: mapping)
    }

    /**
     Returns a Boolean value that indicates whether the receiver implements or inherits a method that can respond to a specified message.
     true if the receiver implements or inherits a method that can respond to aSelector, otherwise false.

     - parameter selector: A selector that identifies a message.

     - returns: `true` if the receiver implements or inherits a method that can respond to aSelector, otherwise `false`.
     */
    open override func responds(to selector: Selector) -> Bool {

        if sizeSelectors.contains(selector) {
            return ds_shouldConsumeItemSizeDelegateCalls()
        }

        return super.responds(to: selector)
    }

    // MARK: - Children DataSources

    open var selectedDataSourceIndex: Int? {
        set {
            if let newValue = newValue {
                selectedDataSource = dataSources[newValue]
            } else {
                selectedDataSource = nil
            }
        }
        get {
            return dataSources.index { $0 === selectedDataSource } ?? -1
        }
    }

    open var selectedDataSource: DataSource?

    private var unsafeSelectedDataSource: DataSource {
        guard let selectedDataSource = selectedDataSource else {
            fatalError("[\(type(of: self))]: Calling DataSource methods with nil selectedDataSource")
        }
        return selectedDataSource
    }

    /// Returns the list of children data sources.
    open private(set) var dataSources: [DataSource] = []

    /**
     Adds a new data source to the list of children data sources.

     - parameter dataSource: The new data source to add.
     */
    open func add(_ dataSource: DataSource) {
        dataSource.ds_reusableViewDelegate = childrenReusableDelegate
        dataSources.append(dataSource)
    }

    /**
     Inserts the data source to the list of children data sources at specific index.

     - parameter dataSource: The new data source to add.
     - parameter index:      The index to insert the new data source at.
     */
    open func insert(_ dataSource: DataSource, at index: Int) {
        dataSource.ds_reusableViewDelegate = childrenReusableDelegate
        dataSources.insert(dataSource, at: index)
    }

    /**
     Removes a data source from the children data sources list.

     - parameter dataSource: The data source to remove.
     */
    open func remove(_ dataSource: DataSource) {
        guard let index = index(of: dataSource)  else { return }
        remove(at: index)
    }

    @discardableResult
    open func remove(at index: Int) -> DataSource {
        let dataSource = dataSources.remove(at: index)
        if dataSource === selectedDataSource {
            selectedDataSource = dataSources.first
        }
        return dataSource
    }

    /// Clear the collection of data sources.
    open func removeAllDataSources() {
        dataSources.removeAll()
        selectedDataSource = nil
    }

    /**
     Returns the data source at certain index.

     - parameter index: The index of the data source to return.

     - returns: The data source at specified index.
     */
    open func dataSource(at index: Int) -> DataSource {
        return dataSources[index]
    }

    /**
     Check if a data source exists or not.

     - parameter dataSource: The data source to check.

     - returns: `true``, if the data source exists. Otherwise `false`.
     */
    open func contains(_ dataSource: DataSource) -> Bool {
        return dataSources.contains { $0 === dataSource }
    }

    /**
     Gets the index of a data source or `nil` if not exist.

     - parameter dataSource: The data source to get the index for.

     - returns: The index of the data source.
     */
    open func index(of dataSource: DataSource) -> Int? {
        return dataSources.index { $0 === dataSource }
    }

    // MARK: - Cell

    /**
     Asks the data source to return the number of sections.

     `1` for Single Section.
     `dataSources.count` for Multi section.

     - returns: The number of sections.
     */
    open override func ds_numberOfSections() -> Int {
        return unsafeSelectedDataSource.ds_numberOfSections()
    }

    /**
     Asks the data source to return the number of items in a given section.

     - parameter section: An index number identifying a section.

     - returns: The number of items in a given section
     */
    open override func ds_numberOfItems(inSection section: Int) -> Int {
        return unsafeSelectedDataSource.ds_numberOfItems(inSection: section)
    }

    /**
     Asks the data source for a cell to insert in a particular location of the general collection view.

     - parameter collectionView: A general collection view object requesting the cell.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: An object conforming to ReusableCell that the view can use for the specified item.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, cellForItemAt indexPath: IndexPath) -> ReusableCell {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, cellForItemAt: indexPath)
    }

    // MARK: - Size

    /**
     Gets whether the data source will handle size delegate calls.
     It only handle delegate calls if the selected data source can.

     - returns: `false` if there is no data sources or any of the data sources cannot handle size delegate calls.
     */
    open override func ds_shouldConsumeItemSizeDelegateCalls() -> Bool {
        return selectedDataSource?.ds_shouldConsumeItemSizeDelegateCalls() ?? false
    }

    /**
     Asks the data source for the size of a cell in a particular location of the general collection view.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: The size of the cell in a given location. For `UITableView`, the width is ignored.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return unsafeSelectedDataSource.ds_collectionView!(collectionView, sizeForItemAt: indexPath)
    }

    // MARK: - Selection

    /**
     Asks the delegate if the specified item should be highlighted.
     `true` if the item should be highlighted or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be highlighted or `false` if it should not.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, shouldHighlightItemAt: indexPath)
    }

    /**
     Tells the delegate that the specified item was highlighted.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */

    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didHighlightItemAt indexPath: IndexPath) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, didHighlightItemAt: indexPath)
    }

    /**
     Tells the delegate that the highlight was removed from the item at the specified index path.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, didUnhighlightItemAt: indexPath)
    }

    /**
     Asks the delegate if the specified item should be selected.
     `true` if the item should be selected or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be selected or `false` if it should not.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, shouldSelectItemAt: indexPath)
    }

    /**
     Tells the delegate that the specified item was selected.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didSelectItemAt indexPath: IndexPath) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, didSelectItemAt: indexPath)
    }

    /**
     Asks the delegate if the specified item should be deselected.
     `true` if the item should be deselected or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be deselected or `false` if it should not.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, shouldDeselectItemAt: indexPath)
    }

    /**
     Tells the delegate that the specified item was deselected.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didDeselectItemAt indexPath: IndexPath) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, didDeselectItemAt: indexPath)
    }

    // MARK: - Header/Footer

    open override func ds_collectionView(_ collectionView: GeneralCollectionView, supplementaryViewOfKind kind: String, at indexPath: IndexPath) -> ReusableSupplementaryView {
        // if, supplementaryViewCreator is not configured use it, otherwise delegate to one of the child data sources
        if supplementaryViewCreator != nil {
            return super.ds_collectionView(collectionView, supplementaryViewOfKind: kind, at: indexPath)
        }
        return unsafeSelectedDataSource.ds_collectionView(collectionView, supplementaryViewOfKind: kind, at: indexPath)
    }

    open override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForSupplementaryViewOfKind kind: String, at indexPath: IndexPath) -> CGSize {
        // if, it's configured use it, otherwise delegate to one of the child data sources
        if supplementaryViewCreator != nil {
            return super.ds_collectionView(collectionView, sizeForSupplementaryViewOfKind: kind, at: indexPath)
        }
        return unsafeSelectedDataSource.ds_collectionView(collectionView, sizeForSupplementaryViewOfKind: kind, at: indexPath)
    }

    open override func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplaySupplementaryView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath) {
        // if, it's configured use it, otherwise delegate to one of the child data sources
        if supplementaryViewCreator != nil {
            return super.ds_collectionView(collectionView, willDisplaySupplementaryView: view, ofKind: kind, at: indexPath)
        }
        return unsafeSelectedDataSource.ds_collectionView(collectionView, willDisplaySupplementaryView: view, ofKind: kind, at: indexPath)
    }

    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didEndDisplayingSupplementaryView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath) {
        // if, it's configured use it, otherwise delegate to one of the child data sources
        if supplementaryViewCreator != nil {
            return super.ds_collectionView(collectionView, didEndDisplayingSupplementaryView: view, ofKind: kind, at: indexPath)
        }
        return unsafeSelectedDataSource.ds_collectionView(collectionView, didEndDisplayingSupplementaryView: view, ofKind: kind, at: indexPath)
    }

    // MARK: - Reordering

    open override func ds_collectionView(_ collectionView: GeneralCollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, canMoveItemAt: indexPath)
    }

    open override func ds_collectionView(_ collectionView: GeneralCollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, moveItemAt: sourceIndexPath, to: destinationIndexPath)
    }

    // MARK: - Cell displaying

    open override func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplay cell: ReusableCell, forItemAt indexPath: IndexPath) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
    }

    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didEndDisplaying cell: ReusableCell, forItemAt indexPath: IndexPath) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
    }

    // MARK: - Copy/Paste

    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, shouldShowMenuForItemAt: indexPath)
    }

    open override func ds_collectionView(_ collectionView: GeneralCollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
    }

    open override func ds_collectionView(_ collectionView: GeneralCollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
    }

    // MARK: - Focus

    @available(iOS 9.0, *)
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, canFocusItemAt: indexPath)
    }

    @available(iOS 9.0, *)
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldUpdateFocusIn context: GeneralCollectionViewFocusUpdateContext) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, shouldUpdateFocusIn: context)
    }

    @available(iOS 9.0, *)
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didUpdateFocusIn context: GeneralCollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, didUpdateFocusIn: context, with: coordinator)
    }

    @available(iOS 9.0, *)
    open override func ds_indexPathForPreferredFocusedView(in collectionView: GeneralCollectionView) -> IndexPath? {
        return unsafeSelectedDataSource.ds_indexPathForPreferredFocusedView(in: collectionView)
    }
}
