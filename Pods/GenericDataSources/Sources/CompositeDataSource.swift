//
//  CompositeDataSource.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 9/16/15.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import UIKit

/**
 The composite data source class that is responsible for managing a set of children data sources.
 Delegating requests to the approperiate child data source to respond.

 Mutli section data source represents multiple sections, each child data source represents a section.
 (e.g. if we have 2 basic data sources first one has 3 items and second one has 4 items,
 then we have 2 sections first one will have 3 cells and second one will have 4 cells.)

 Single section data source represents one section, children data sources are all on the same section.
 (e.g. if we have 2 basic data sources first one has 3 items and second one has 4 items,
 then we have 1 section with 7 cells, the first 3 cells will be dequeued and configured by the first
 basic data source followed by 4 cells dequeued and configured by the second data source.)

 It's recommended to subclass it if you want to have a common behavior.
 (e.g. If all the cells will have a common cell size. Then, implement `ds_responds(to:.size)` and return `true`, then implement
 `ds_collectionView(_:sizeForItemAt:)` and return the desired size for all
 the cells regardless of the children data sources.)
 */
open class CompositeDataSource: AbstractDataSource, CollectionDataSource {

    /// The type of the composite data source.
    public enum SectionType {
        /// Single section data source represents one section, children data sources are all on the same section.
        case single
        /// Mutli section data source represents multiple sections, each child data source represents a section.
        case multi
    }

    /// The collection class that manages the data sources.
    private var collection: _DataSourcesCollection!

    ///  Represents the section type of the composite data source.
    public let sectionType: SectionType

    /// Returns a string that describes the contents of the receiver.
    open override var description: String {
        let properties: [(String, Any?)] = [
            ("sectionType", sectionType),
            ("scrollViewDelegate", scrollViewDelegate),
            ("supplementaryViewCreator", supplementaryViewCreator)]
        return describe(self, properties: properties)
    }

    /**
     Creates new instance with the desired type.

     - parameter sectionType: The desired composite data source type.
     */
    public init(sectionType: SectionType) {
        self.sectionType = sectionType
        super.init()

        switch sectionType {
        case .single:
            collection = _SingleSectionDataSourcesCollection(parentDataSource: self)
        case .multi:
            collection = _MultiSectionDataSourcesCollection(parentDataSource: self)
        }
    }

    // MARK: - Children DataSources

    /// Returns the list of children data sources.
    open var dataSources: [DataSource] {
        return collection.dataSources
    }

    /**
     Adds a new data source to the list of children data sources.

     - parameter dataSource: The new data source to add.
     */
    open func add(_ dataSource: DataSource) {
        collection.add(dataSource)
    }

    /**
     Inserts the data source to the list of children data sources at specific index.

     - parameter dataSource: The new data source to add.
     - parameter index:      The index to insert the new data source at.
     */
    open func insert(_ dataSource: DataSource, at index: Int) {
        collection.insert(dataSource, at: index)
    }

    /**
     Removes a data source from the children data sources list.

     - parameter dataSource: The data source to remove.
     */
    open func remove(_ dataSource: DataSource) {
        collection.remove(dataSource)
    }

    /// Removes data source at the specified index.
    ///
    /// - Parameter index: The index of the data source to remove.
    /// - Returns: The removed data source.
    @discardableResult
    open func remove(at index: Int) -> DataSource {
        return collection.remove(at: index)
    }

    /// Clear the collection of data sources.
    open func removeAllDataSources() {
        collection.removeAllDataSources()
    }

    /**
     Returns the data source at certain index.

     - parameter index: The index of the data source to return.

     - returns: The data source at specified index.
     */
    open func dataSource(at index: Int) -> DataSource {
        return collection.dataSource(at: index)
    }

    /**
     Check if a data source exists or not.

     - parameter dataSource: The data source to check.

     - returns: `true``, if the data source exists. Otherwise `false`.
     */
    open func contains(_ dataSource: DataSource) -> Bool {
        return collection.contains(dataSource)
    }

    /**
     Gets the index of a data source or `nil` if not exist.

     - parameter dataSource: The data source to get the index for.

     - returns: The index of the data source.
     */
    open func index(of dataSource: DataSource) -> Int? {
        return collection.index(of: dataSource)
    }

    // MARK: - Responds

    /// Asks the data source if it responds to a given selector.
    ///
    /// This method returns `true` if the children data sources can respond to the selector.
    ///
    /// - Parameter selector: The selector to check if the instance repsonds to.
    /// - Returns: `true` if the instance responds to the passed selector, otherwise `false`.
    open override func ds_responds(to selector: DataSourceSelector) -> Bool {

        // we always define last one as DataSource selector.
        let theSelector = dataSourceSelectorToSelectorMapping[selector]!.last!
        // check if the subclass implemented the selector, always return true
        if subclassHasDifferentImplmentation(type: CompositeDataSource.self, selector: theSelector) {
            return true
        }

        if dataSources.isEmpty {
            return false
        }
        if selector.mustAllRespondsToIt {
            return dataSources.filter { $0.ds_responds(to: selector) }.count == dataSources.count
        } else {
            return dataSources.contains { $0.ds_responds(to: selector) }
        }
    }

    // MARK: - IndexPath and Section translations

    /**
     Converts a section value relative to a specific data source to a section value relative to the composite data source.

     - parameter section:       The local section relative to the passed data source.
     - parameter dataSource:    The data source that is the local section is relative to it. Should be a child data source.

     - returns: The global section relative to the composite data source.
     */
    open func globalSectionForLocalSection(_ section: Int, dataSource: DataSource) -> Int {
        return collection.globalSectionForLocalSection(section, dataSource: dataSource)
    }

    /**
     Converts a section value relative to the composite data source to a section value relative to a specific data source.

     - parameter section:    The section relative to the compsite data source.
     - parameter dataSource: The data source that is the returned local section is relative to it. Should be a child data source.

     - returns: The global section relative to the composite data source.
     */
    open func localSectionForGlobalSection(_ section: Int, dataSource: DataSource) -> Int {
        return collection.localSectionForGlobalSection(section, dataSource: dataSource)
    }

    /**
     Converts an index path value relative to a specific data source to an index path value relative to the composite data source.

     - parameter indexPath:     The local index path relative to the passed data source.
     - parameter dataSource:    The data source that is the local index path is relative to it. Should be a child data source.

     - returns: The global index path relative to the composite data source.
     */
    open func globalIndexPathForLocalIndexPath(_ indexPath: IndexPath, dataSource: DataSource) -> IndexPath {
        return collection.globalIndexPathForLocalIndexPath(indexPath, dataSource: dataSource)
    }

    /**
     Converts an index path value relative to the composite data source to an index path value relative to a specific data source.

     - parameter indexPath:    The index path relative to the compsite data source.
     - parameter dataSource: The data source that is the returned local index path is relative to it. Should be a child data source.

     - returns: The global index path relative to the composite data source.
     */
    open func localIndexPathForGlobalIndexPath(_ indexPath: IndexPath, dataSource: DataSource) -> IndexPath {
        return collection.localIndexPathForGlobalIndexPath(indexPath, dataSource: dataSource)
    }

    /// Transform the passed index path and collection view to a local/child data source, index path and collection view. **Crashes if mapping doesn't exist.**
    ///
    /// This method should only be used to add new capabilities to the `CompositeDataSource`.
    /// It shouldn't be used for regular usage of the data sources in app.
    ///
    /// If you want to extend `CompositeDataSource`, you might have a local at one of the implementation of `DataSource` that uses this method.
    /// Usually, you do it in 2 steps:
    /// 1. Transform using this method the passed collection view and datasource.
    /// 2. Use the transformed value to call the new data source with a new collection view and new index path.
    ///
    /// **You shouldn't by any case combine global and local data.** Like calling a local data source with global collection view.
    ///
    /// - parameter globalIndexPath:      The global index path, it's local for the `CompositeDataSource`. But global for child data sources.
    /// - parameter globalCollectionView: The global collect view, it's local for the `CompositeDataSource`. But global for child data sources.
    ///
    /// - returns: The transformed result that contains (new local data source, new local collection view and new local index path).
    open func unsafeTransform(globalIndexPath: IndexPath, globalCollectionView: GeneralCollectionView) -> LocalDataSourceCollectionView {
        return collection.unsafeTransform(globalIndexPath: globalIndexPath, globalCollectionView: globalCollectionView)
    }

    /// Transform the passed index path and collection view to a local/child data source, index path and collection view.
    ///
    /// This method should only be used to add new capabilities to the `CompositeDataSource`.
    /// It shouldn't be used for regular usage of the data sources in app.
    ///
    /// If you want to extend `CompositeDataSource`, you might have a local at one of the implementation of `DataSource` that uses this method.
    /// Usually, you do it in 2 steps:
    /// 1. Transform using this method the passed collection view and datasource.
    /// 2. Use the transformed value to call the new data source with a new collection view and new index path.
    ///
    /// **You shouldn't by any case combine global and local data.** Like calling a local data source with global collection view.
    ///
    /// - parameter globalIndexPath:      The global index path, it's local for the `CompositeDataSource`. But global for child data sources.
    /// - parameter globalCollectionView: The global collect view, it's local for the `CompositeDataSource`. But global for child data sources.
    ///
    /// - returns: The transformed result that contains (new local data source, new local collection view and new local index path).
    open func transform(globalIndexPath: IndexPath, globalCollectionView: GeneralCollectionView) -> LocalDataSourceCollectionView? {
        return collection.transform(globalIndexPath: globalIndexPath, globalCollectionView: globalCollectionView)
    }

    // MARK: - Cell

    /**
     Asks the data source to return the number of sections.

     `1` for Single Section.
     `dataSources.count` for Multi section.

     - returns: The number of sections.
     */
    open override func ds_numberOfSections() -> Int {
        return collection.numberOfSections()
    }

    /**
     Asks the data source to return the number of items in a given section.

     - parameter section: An index number identifying a section.

     - returns: The number of items in a given section
     */
    open override func ds_numberOfItems(inSection section: Int) -> Int {
        return collection.numberOfItems(inSection: section)
    }

    /**
     Asks the data source for a cell to insert in a particular location of the general collection view.

     - parameter collectionView: A general collection view object requesting the cell.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: An object conforming to ReusableCell that the view can use for the specified item.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, cellForItemAt indexPath: IndexPath) -> ReusableCell {

        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(transformed.collectionView, cellForItemAt: transformed.indexPath)
    }

    // MARK: - Size

    /**
     Asks the data source for the size of a cell in a particular location of the general collection view.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: The size of the cell in a given location. For `UITableView`, the width is ignored.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView!(transformed.collectionView, sizeForItemAt: transformed.indexPath)
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
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(transformed.collectionView, shouldHighlightItemAt: transformed.indexPath)
    }

    /**
     Tells the delegate that the specified item was highlighted.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */

    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didHighlightItemAt indexPath: IndexPath) {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(transformed.collectionView, didHighlightItemAt: transformed.indexPath)
    }

    /**
     Tells the delegate that the highlight was removed from the item at the specified index path.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, didUnhighlightItemAt: transformed.indexPath)
    }

    /**
     Asks the delegate if the specified item should be selected.
     `true` if the item should be selected or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be selected or `false` if it should not.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, shouldSelectItemAt: transformed.indexPath)
    }

    /**
     Tells the delegate that the specified item was selected.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didSelectItemAt indexPath: IndexPath) {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(transformed.collectionView, didSelectItemAt: transformed.indexPath)
    }

    /**
     Asks the delegate if the specified item should be deselected.
     `true` if the item should be deselected or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be deselected or `false` if it should not.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, shouldDeselectItemAt: transformed.indexPath)
    }

    /**
     Tells the delegate that the specified item was deselected.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didDeselectItemAt indexPath: IndexPath) {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(transformed.collectionView, didDeselectItemAt: transformed.indexPath)
    }

    // MARK: - Header/Footer

    private func delegateSupplementaryViewCalls(collectionView: GeneralCollectionView, indexPath: IndexPath) -> LocalDataSourceCollectionView? {
        guard supplementaryViewCreator == nil else { return nil }
        guard let transformed = transform(globalIndexPath: indexPath, globalCollectionView: collectionView) else { return nil }
        return transformed
    }

    /// Retrieves the supplementary view for the passed kind at the passed index path.
    ///
    /// This method first checks if there is `supplementaryViewCreator` set to this data source and use it.
    /// Otherwise, it delegates this method to the approperiate child data source.
    ///
    /// - Parameters:
    ///   - collectionView: The collectionView requesting the supplementary view.
    ///   - kind: The kind of the supplementary view.
    ///   - indexPath: The indexPath at which the supplementary view is requested.
    /// - Returns: The supplementary view for the passed index path.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, supplementaryViewOfKind kind: String, at indexPath: IndexPath) -> ReusableSupplementaryView? {
        // if, supplementaryViewCreator is not configured use it, otherwise delegate to one of the child data sources
        guard let transformed = delegateSupplementaryViewCalls(collectionView: collectionView, indexPath: indexPath) else {
            return super.ds_collectionView(collectionView, supplementaryViewOfKind: kind, at: indexPath)
        }
        return transformed.dataSource.ds_collectionView(transformed.collectionView, supplementaryViewOfKind: kind, at: transformed.indexPath)
    }

    /// Gets the size of supplementary view for the passed kind at the passed index path.
    ///
    /// This method first checks if there is `supplementaryViewCreator` set to this data source and use it.
    /// Otherwise, it delegates this method to the approperiate child data source.
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
        guard let transformed = delegateSupplementaryViewCalls(collectionView: collectionView, indexPath: indexPath) else {
            return super.ds_collectionView(collectionView, sizeForSupplementaryViewOfKind: kind, at: indexPath)
        }
        return transformed.dataSource.ds_collectionView(transformed.collectionView, sizeForSupplementaryViewOfKind: kind, at: transformed.indexPath)
    }

    /// Supplementary view is about to be displayed. Called exactly before the supplementary view is displayed.
    ///
    /// This method first checks if there is `supplementaryViewCreator` set to this data source and use it.
    /// Otherwise, it delegates this method to the approperiate child data source.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplaySupplementaryView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath) {
        // if, it's configured use it, otherwise delegate to one of the child data sources
        guard let transformed = delegateSupplementaryViewCalls(collectionView: collectionView, indexPath: indexPath) else {
            return super.ds_collectionView(collectionView, willDisplaySupplementaryView: view, ofKind: kind, at: indexPath)
        }
        return transformed.dataSource.ds_collectionView(transformed.collectionView, willDisplaySupplementaryView: view, ofKind: kind, at: transformed.indexPath)
    }

    /// Supplementary view has been displayed and user scrolled it out of the screen.
    /// Called exactly after the supplementary view is scrolled out of the screen.
    ///
    /// This method first checks if there is `supplementaryViewCreator` set to this data source and use it.
    /// Otherwise, it delegates this method to the approperiate child data source.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didEndDisplayingSupplementaryView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath) {
        // if, it's configured use it, otherwise delegate to one of the child data sources
        guard let transformed = delegateSupplementaryViewCalls(collectionView: collectionView, indexPath: indexPath) else {
            return super.ds_collectionView(collectionView, didEndDisplayingSupplementaryView: view, ofKind: kind, at: indexPath)
        }
        return transformed.dataSource.ds_collectionView(transformed.collectionView, didEndDisplayingSupplementaryView: view, ofKind: kind, at: transformed.indexPath)
    }

    // MARK: - Reordering

    /// Asks the delegate if the item can be moved for a reoder operation.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can be moved, otherwise `false`.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, canMoveItemAt: transformed.indexPath)
    }

    /// Performs the move operation of an item from `sourceIndexPath` to `destinationIndexPath`.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - sourceIndexPath: An index path locating the start position of the item in the view.
    ///   - destinationIndexPath: An index path locating the end position of the item in the view.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let transformedSource = unsafeTransform(globalIndexPath: sourceIndexPath, globalCollectionView: collectionView)
        let transformedDestination = unsafeTransform(globalIndexPath: destinationIndexPath, globalCollectionView: collectionView)
        precondition(transformedSource.dataSource === transformedDestination.dataSource, "Moving items between data sources is not supported yet. You can do it manually by overriding ds_collectionView(_:moveItemAt:to:) in your \(type(of: self))")
        return transformedSource.dataSource.ds_collectionView(collectionView, moveItemAt: transformedSource.indexPath, to: transformedDestination.indexPath)
    }

    // MARK: - Cell displaying

    /// The cell will is about to be displayed or moving into the visible area of the screen.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - cell: The cell that will be displayed
    ///   - indexPath: An index path locating an item in the view.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplay cell: ReusableCell, forItemAt indexPath: IndexPath) {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, willDisplay: cell, forItemAt: transformed.indexPath)
    }

    /// The cell will is already displayed and will be moving out of the screen.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - cell: The cell that will be displayed
    ///   - indexPath: An index path locating an item in the view.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didEndDisplaying cell: ReusableCell, forItemAt indexPath: IndexPath) {
        guard let transformed = transform(globalIndexPath: indexPath, globalCollectionView: collectionView) else {
            return super.ds_collectionView(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
        }
        return transformed.dataSource.ds_collectionView(collectionView, didEndDisplaying: cell, forItemAt: transformed.indexPath)
    }

    // MARK: - Copy/Paste

    /// Whether the copy/paste/etc. menu should be shown for the item or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item should show the copy/paste/etc. menu, otherwise `false`.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, shouldShowMenuForItemAt: transformed.indexPath)
    }

    /// Check whether an action/selector can be performed for a specific item or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - action: The action that is requested to check if it can be performed or not.
    ///   - indexPath: An index path locating an item in the view.
    ///   - sender: The sender of the action.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, canPerformAction: action, forItemAt: transformed.indexPath, withSender: sender)
    }

    /// Executes an action for a specific item with the passed sender.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - action: The action that is requested to be executed.
    ///   - indexPath: An index path locating an item in the view.
    ///   - sender: The sender of the action.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, performAction: action, forItemAt: transformed.indexPath, withSender: sender)
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
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, canFocusItemAt: transformed.indexPath)
    }

    /// Whether or not should we update the focus.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - context: The focus context.
    /// - Returns: `true` if the item can be moved, otherwise `false`.
    @available(iOS 9.0, *)
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldUpdateFocusIn context: GeneralCollectionViewFocusUpdateContext) -> Bool {
        // simply call the super, since we cannot transform this as it dosen't ask for a specific class.
        // usually the outermost datasource is the one responsible for handling this call.
        return super.ds_collectionView(collectionView, shouldUpdateFocusIn: context)
    }

    /// The focus is has been updated.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - context: The focus context.
    ///   - coordinator: The focus animation coordinator.
    @available(iOS 9.0, *)
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didUpdateFocusIn context: GeneralCollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        // simply call the super, since we cannot transform this as it dosen't ask for a specific class.
        // usually the outermost datasource is the one responsible for handling this call.
        return super.ds_collectionView(collectionView, didUpdateFocusIn: context, with: coordinator)
    }

    /// Gets the index path of the preferred focused view.
    ///
    /// - Parameter collectionView: A general collection view object initiating the operation.
    @available(iOS 9.0, *)
    open override func ds_indexPathForPreferredFocusedView(in collectionView: GeneralCollectionView) -> IndexPath? {
        // simply call the super, since we cannot transform this as it dosen't ask for a specific class.
        // usually the outermost datasource is the one responsible for handling this call.
        return super.ds_indexPathForPreferredFocusedView(in: collectionView)
    }

    // MARK: - Editing

    /// Check whether the item can be edited or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can be moved, otherwise `false`.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, canEditItemAt: transformed.indexPath)
    }

    /// Executes the editing operation for the item at the specified index pass.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - editingStyle: The
    ///   - indexPath: An index path locating an item in the view.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, commit editingStyle: UITableViewCell.EditingStyle, forItemAt indexPath: IndexPath) {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, commit: editingStyle, forItemAt: transformed.indexPath)
    }

    /// Gets the editing style for an item.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: The editing style.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, editingStyleForItemAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, editingStyleForItemAt: transformed.indexPath)
    }

    /// Gets the localized title for the delete button to show for editing an item (e.g. swipe to delete).
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: The localized title string.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, titleForDeleteConfirmationButtonForItemAt indexPath: IndexPath) -> String? {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, titleForDeleteConfirmationButtonForItemAt: transformed.indexPath)
    }

    /// Gets the list of editing actions to use for editing an item.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: The list of editing actions.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, editActionsForItemAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, editActionsForItemAt: transformed.indexPath)
    }

    /// Check whether to indent the item while editing or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can be indented while editing, otherwise `false`.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldIndentWhileEditingItemAt indexPath: IndexPath) -> Bool {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, shouldIndentWhileEditingItemAt: transformed.indexPath)
    }

    /// The item is about to enter into the editing mode.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, willBeginEditingItemAt indexPath: IndexPath) {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, willBeginEditingItemAt: transformed.indexPath)
    }

    /// The item did leave the editing mode.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didEndEditingItemAt indexPath: IndexPath) {
        let transformed = unsafeTransform(globalIndexPath: indexPath, globalCollectionView: collectionView)
        return transformed.dataSource.ds_collectionView(collectionView, didEndEditingItemAt: transformed.indexPath)
    }
}
