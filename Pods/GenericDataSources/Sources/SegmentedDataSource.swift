//
//  SegmentedDataSource.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 11/13/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/// The composite data source class that is responsible for managing a set of children data sources.
/// Delegating requests to the selected child data source to respond.
/// If the `selectedDataSource` is nil, calls to `DataSource` methods will crash.
open class SegmentedDataSource: AbstractDataSource, CollectionDataSource {

    /// Returns a string that describes the contents of the receiver.
    open override var description: String {
        let properties: [(String, Any?)] = [
            ("selectedDataSource", selectedDataSource),
            ("scrollViewDelegate", scrollViewDelegate),
            ("supplementaryViewCreator", supplementaryViewCreator)]
        return describe(self, properties: properties)
    }

    private var childrenReusableDelegate: _DelegatedGeneralCollectionView! // swiftlint:disable:this weak_delegate

    /// Creates new instance.
    public override init() {
        super.init()
        let mapping = _SegmentedGeneralCollectionViewMapping(parentDataSource: self)
        childrenReusableDelegate = _DelegatedGeneralCollectionView(mapping: mapping)
    }

    // MARK: - Children DataSources

    /// Represents the selected data source index or `NSNotFound` if no data source selected.
    open var selectedDataSourceIndex: Int {
        set {
            precondition(newValue < dataSources.count, "[GenericDataSource] invalid selectedDataSourceIndex, should be less than \(dataSources.count)")
            precondition(newValue >= 0, "[GenericDataSource] invalid selectedDataSourceIndex, should be greater than or equal to 0.")
            selectedDataSource = dataSources[newValue]
        }
        get {
            return dataSources.index { $0 === selectedDataSource } ?? NSNotFound
        }
    }

    /// Represents the selected data source or nil if not selected.
    open var selectedDataSource: DataSource?

    private var unsafeSelectedDataSource: DataSource {
        guard let selectedDataSource = selectedDataSource else {
            fatalError("[\(type(of: self))]: Calling SegmentedDataSource methods with nil selectedDataSource")
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
        if selectedDataSource == nil {
            selectedDataSource = dataSource
        }
    }

    /**
     Inserts the data source to the list of children data sources at specific index.

     - parameter dataSource: The new data source to add.
     - parameter index:      The index to insert the new data source at.
     */
    open func insert(_ dataSource: DataSource, at index: Int) {
        dataSource.ds_reusableViewDelegate = childrenReusableDelegate
        dataSources.insert(dataSource, at: index)
        if selectedDataSource == nil {
            selectedDataSource = dataSource
        }
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

    // MARK: - Responds

    /// Asks the data source if it responds to a given selector.
    ///
    /// This method returns `true` if the selected data source can respond to the selector.
    ///
    /// - Parameter selector: The selector to check if the instance repsonds to.
    /// - Returns: `true` if the instance responds to the passed selector, otherwise `false`.
    open override func ds_responds(to selector: DataSourceSelector) -> Bool {
        // we always define last one as DataSource selector.
        let theSelector = dataSourceSelectorToSelectorMapping[selector]!.last!
        // check if the subclass implemented the selector, always return true
        if subclassHasDifferentImplmentation(type: SegmentedDataSource.self, selector: theSelector) {
            return true
        }
        return selectedDataSource?.ds_responds(to: selector) ?? false
    }

    // MARK: - IndexPath and Section translations

    /**
     Converts a section value relative to a specific data source to a section value relative to the composite data source.

     - parameter section:       The local section relative to the passed data source.
     - parameter dataSource:    The data source that is the local section is relative to it. Should be a child data source.

     - returns: The global section relative to the composite data source.
     */
    open func globalSectionForLocalSection(_ section: Int, dataSource: DataSource) -> Int {
        return section
    }

    /**
     Converts a section value relative to the composite data source to a section value relative to a specific data source.

     - parameter section:    The section relative to the compsite data source.
     - parameter dataSource: The data source that is the returned local section is relative to it. Should be a child data source.

     - returns: The global section relative to the composite data source.
     */
    open func localSectionForGlobalSection(_ section: Int, dataSource: DataSource) -> Int {
        return section
    }

    /**
     Converts an index path value relative to a specific data source to an index path value relative to the composite data source.

     - parameter indexPath:     The local index path relative to the passed data source.
     - parameter dataSource:    The data source that is the local index path is relative to it. Should be a child data source.

     - returns: The global index path relative to the composite data source.
     */
    open func globalIndexPathForLocalIndexPath(_ indexPath: IndexPath, dataSource: DataSource) -> IndexPath {
        return indexPath
    }

    /**
     Converts an index path value relative to the composite data source to an index path value relative to a specific data source.

     - parameter indexPath:    The index path relative to the compsite data source.
     - parameter dataSource: The data source that is the returned local index path is relative to it. Should be a child data source.

     - returns: The global index path relative to the composite data source.
     */
    open func localIndexPathForGlobalIndexPath(_ indexPath: IndexPath, dataSource: DataSource) -> IndexPath {
        return indexPath
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

    /// Retrieves the supplementary view for the passed kind at the passed index path.
    ///
    /// - Parameters:
    ///   - collectionView: The collectionView requesting the supplementary view.
    ///   - kind: The kind of the supplementary view.
    ///   - indexPath: The indexPath at which the supplementary view is requested.
    /// - Returns: The supplementary view for the passed index path.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, supplementaryViewOfKind kind: String, at indexPath: IndexPath) -> ReusableSupplementaryView? {
        // if, supplementaryViewCreator is not configured use it, otherwise delegate to one of the child data sources
        if supplementaryViewCreator != nil {
            return super.ds_collectionView(collectionView, supplementaryViewOfKind: kind, at: indexPath)
        }
        return unsafeSelectedDataSource.ds_collectionView(collectionView, supplementaryViewOfKind: kind, at: indexPath)
    }

    /// Gets the size of supplementary view for the passed kind at the passed index path.
    ///
    /// * For `UITableView` just supply the height width is don't care.
    /// * For `UICollectionViewFlowLayout` supply the height if it's vertical scrolling, or width if it's horizontal scrolling.
    /// * Specifying `CGSize.zero`, means don't display a supplementary view and `viewOfKind` will not be called.
    ///
    /// - Parameters:
    ///   - collectionView: The collectionView requesting the supplementary view.
    ///   - kind: The kind of the supplementary view.
    ///   - indexPath: The indexPath at which the supplementary view is requested.
    /// - Returns: The size of the supplementary view.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForSupplementaryViewOfKind kind: String, at indexPath: IndexPath) -> CGSize {
        // if, it's configured use it, otherwise delegate to one of the child data sources
        if supplementaryViewCreator != nil {
            return super.ds_collectionView(collectionView, sizeForSupplementaryViewOfKind: kind, at: indexPath)
        }
        return unsafeSelectedDataSource.ds_collectionView(collectionView, sizeForSupplementaryViewOfKind: kind, at: indexPath)
    }

    /// Supplementary view is about to be displayed. Called exactly before the supplementary view is displayed.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplaySupplementaryView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath) {
        // if, it's configured use it, otherwise delegate to one of the child data sources
        if supplementaryViewCreator != nil {
            return super.ds_collectionView(collectionView, willDisplaySupplementaryView: view, ofKind: kind, at: indexPath)
        }
        return unsafeSelectedDataSource.ds_collectionView(collectionView, willDisplaySupplementaryView: view, ofKind: kind, at: indexPath)
    }

    /// Supplementary view has been displayed and user scrolled it out of the screen.
    /// Called exactly after the supplementary view is scrolled out of the screen.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didEndDisplayingSupplementaryView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath) {
        // if, it's configured use it, otherwise delegate to one of the child data sources
        if supplementaryViewCreator != nil {
            return super.ds_collectionView(collectionView, didEndDisplayingSupplementaryView: view, ofKind: kind, at: indexPath)
        }
        return unsafeSelectedDataSource.ds_collectionView(collectionView, didEndDisplayingSupplementaryView: view, ofKind: kind, at: indexPath)
    }

    // MARK: - Reordering

    /// Asks the delegate if the item can be moved for a reoder operation.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can be moved, otherwise `false`.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, canMoveItemAt: indexPath)
    }

    /// Performs the move operation of an item from `sourceIndexPath` to `destinationIndexPath`.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - sourceIndexPath: An index path locating the start position of the item in the view.
    ///   - destinationIndexPath: An index path locating the end position of the item in the view.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, moveItemAt: sourceIndexPath, to: destinationIndexPath)
    }

    // MARK: - Cell displaying

    /// The cell will is about to be displayed or moving into the visible area of the screen.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - cell: The cell that will be displayed
    ///   - indexPath: An index path locating an item in the view.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplay cell: ReusableCell, forItemAt indexPath: IndexPath) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
    }

    /// The cell will is already displayed and will be moving out of the screen.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - cell: The cell that will be displayed
    ///   - indexPath: An index path locating an item in the view.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didEndDisplaying cell: ReusableCell, forItemAt indexPath: IndexPath) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
    }

    // MARK: - Copy/Paste

    /// Whether the copy/paste/etc. menu should be shown for the item or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item should show the copy/paste/etc. menu, otherwise `false`.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, shouldShowMenuForItemAt: indexPath)
    }

    /// Check whether an action/selector can be performed for a specific item or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - action: The action that is requested to check if it can be performed or not.
    ///   - indexPath: An index path locating an item in the view.
    ///   - sender: The sender of the action.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
    }

    /// Executes an action for a specific item with the passed sender.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - action: The action that is requested to be executed.
    ///   - indexPath: An index path locating an item in the view.
    ///   - sender: The sender of the action.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
    }

    // MARK: - Focus

    /// Whether or not the item can have focus.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can have focus, otherwise `false`.
    @available(iOS 9.0, *)
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, canFocusItemAt: indexPath)
    }

    /// Whether or not should we update the focus.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - context: The focus context.
    /// - Returns: `true` if the item can be moved, otherwise `false`.
    @available(iOS 9.0, *)
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldUpdateFocusIn context: GeneralCollectionViewFocusUpdateContext) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, shouldUpdateFocusIn: context)
    }

    /// The focus is has been updated.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - context: The focus context.
    ///   - coordinator: The focus animation coordinator.
    @available(iOS 9.0, *)
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didUpdateFocusIn context: GeneralCollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, didUpdateFocusIn: context, with: coordinator)
    }

    /// Gets the index path of the preferred focused view.
    ///
    /// - Parameter collectionView: A general collection view object initiating the operation.
    @available(iOS 9.0, *)
    open override func ds_indexPathForPreferredFocusedView(in collectionView: GeneralCollectionView) -> IndexPath? {
        return unsafeSelectedDataSource.ds_indexPathForPreferredFocusedView(in: collectionView)
    }

    // MARK: - Editing

    /// Check whether the item can be edited or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can be moved, otherwise `false`.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, canEditItemAt: indexPath)
    }

    /// Executes the editing operation for the item at the specified index pass.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - editingStyle: The
    ///   - indexPath: An index path locating an item in the view.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, commit editingStyle: UITableViewCell.EditingStyle, forItemAt indexPath: IndexPath) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, commit: editingStyle, forItemAt: indexPath)
    }

    /// Gets the editing style for an item.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: The editing style.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, editingStyleForItemAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, editingStyleForItemAt: indexPath)
    }

    /// Gets the localized title for the delete button to show for editing an item (e.g. swipe to delete).
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: The localized title string.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, titleForDeleteConfirmationButtonForItemAt indexPath: IndexPath) -> String? {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, titleForDeleteConfirmationButtonForItemAt: indexPath)
    }

    /// Gets the list of editing actions to use for editing an item.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: The list of editing actions.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, editActionsForItemAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, editActionsForItemAt: indexPath)
    }

    /// Check whether to indent the item while editing or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can be indented while editing, otherwise `false`.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldIndentWhileEditingItemAt indexPath: IndexPath) -> Bool {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, shouldIndentWhileEditingItemAt: indexPath)
    }

    /// The item is about to enter into the editing mode.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, willBeginEditingItemAt indexPath: IndexPath) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, willBeginEditingItemAt: indexPath)
    }

    /// The item did leave the editing mode.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didEndEditingItemAt indexPath: IndexPath) {
        return unsafeSelectedDataSource.ds_collectionView(collectionView, didEndEditingItemAt: indexPath)
    }
}
