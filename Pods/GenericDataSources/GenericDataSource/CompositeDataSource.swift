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
 (e.g. If all the cells will have a common cell size. Then, implement `ds_shouldConsumeItemSizeDelegateCalls` and return `true`, then implement
 `ds_collectionView(_:sizeForItemAtIndexPath:)` and return the desired size for all
 the cells regardless of the children data sources.)
 */
public class CompositeDataSource: AbstractDataSource {

    /**
     The type of the composite data source.

     - SingleSection: Single section data source represents one section, children data sources are all on the same section.
     - MultiSection:  Mutli section data source represents multiple sections, each child data source represents a section.
     */
    public enum Type {
        case SingleSection
        case MultiSection
    }

    /// The collection class that manages the data sources.
    private var collection: DataSourcesCollection!

    ///  Represents the type of the composite data source.
    public let type: Type

    /**
     Creates new instance with the desired type.

     - parameter type: The desired composite data source type.
     */
    public init(type: Type) {
        self.type = type
        super.init()

        switch type {
        case .SingleSection:
            collection = SingleSectionDataSourcesCollection(parentDataSource: self)
        case .MultiSection:
            collection = MultiSectionDataSourcesCollection(parentDataSource: self)
        }
    }

    /// Returns the list of children data sources.
    public var dataSources: [DataSource] {
        return collection.dataSources
    }

    /**
     Returns a Boolean value that indicates whether the receiver implements or inherits a method that can respond to a specified message.
     true if the receiver implements or inherits a method that can respond to aSelector, otherwise false.

     - parameter selector: A selector that identifies a message.

     - returns: `true` if the receiver implements or inherits a method that can respond to aSelector, otherwise `false`.
     */
    public override func respondsToSelector(selector: Selector) -> Bool {

        if sizeSelectors.contains(selector) {
            return ds_shouldConsumeItemSizeDelegateCalls()
        }

        return super.respondsToSelector(selector)
    }

    // MARK: Children DataSources

    /**
     Adds a new data source to the list of children data sources.

     - parameter dataSource: The new data source to add.
     */
    public func addDataSource(dataSource: DataSource) {
        collection.addDataSource(dataSource)
    }

    /**
     Inserts the data source to the list of children data sources at specific index.

     - parameter dataSource: The new data source to add.
     - parameter index:      The index to insert the new data source at.
     */
    public func insertDataSource(dataSource: DataSource, atIndex index: Int) {
        collection.insertDataSource(dataSource, atIndex: index)
    }

    /**
     Removes a data source from the children data sources list.

     - parameter dataSource: The data source to remove.
     */
    public func removeDataSource(dataSource: DataSource) {
        collection.removeDataSource(dataSource)
    }

    /**
     Returns the data source at certain index.

     - parameter index: The index of the data source to return.

     - returns: The data source at specified index.
     */
    public func dataSourceAtIndex(index: Int) -> DataSource {
        return collection.dataSourceAtIndex(index)
    }

    /**
     Check if a data source exists or not.

     - parameter dataSource: The data source to check.

     - returns: `true``, if the data source exists. Otherwise `false`.
     */
    public func containsDataSource(dataSource: DataSource) -> Bool {
        return collection.containsDataSource(dataSource)
    }

    /**
     Gets the index of a data source or `nil` if not exist.

     - parameter dataSource: The data source to get the index for.

     - returns: The index of the data source.
     */
    public func indexOfDataSource(dataSource: DataSource) -> Int? {
        return collection.indexOfDataSource(dataSource)
    }

    // MARK:- IndexPath and Section translations

    /**
     Converts a section value relative to a specific data source to a section value relative to the composite data source.

     - parameter section:       The local section relative to the passed data source.
     - parameter dataSource:    The data source that is the local section is relative to it. Should be a child data source.

     - returns: The global section relative to the composite data source.
     */
    public func globalSectionForLocalSection(section: Int, dataSource: DataSource) -> Int {
        return collection.globalSectionForLocalSection(section, dataSource: dataSource)
    }

    /**
     Converts a section value relative to the composite data source to a section value relative to a specific data source.

     - parameter section:    The section relative to the compsite data source.
     - parameter dataSource: The data source that is the returned local section is relative to it. Should be a child data source.

     - returns: The global section relative to the composite data source.
     */
    public func localSectionForGlobalSection(section: Int, dataSource: DataSource) -> Int {
        return collection.localSectionForGlobalSection(section, dataSource: dataSource)
    }

    /**
     Converts an index path value relative to a specific data source to an index path value relative to the composite data source.

     - parameter indexPath:     The local index path relative to the passed data source.
     - parameter dataSource:    The data source that is the local index path is relative to it. Should be a child data source.

     - returns: The global index path relative to the composite data source.
     */
    public func globalIndexPathForLocalIndexPath(indexPath: NSIndexPath, dataSource: DataSource) -> NSIndexPath {
        return collection.globalIndexPathForLocalIndexPath(indexPath, dataSource: dataSource)
    }

    /**
     Converts an index path value relative to the composite data source to an index path value relative to a specific data source.

     - parameter indexPath:    The index path relative to the compsite data source.
     - parameter dataSource: The data source that is the returned local index path is relative to it. Should be a child data source.

     - returns: The global index path relative to the composite data source.
     */
    public func localIndexPathForGlobalIndexPath(indexPath: NSIndexPath, dataSource: DataSource) -> NSIndexPath {
        return collection.localIndexPathForGlobalIndexPath(indexPath, dataSource: dataSource)
    }

    // MARK:- Data Source

    /**
     Gets whether the data source will handle size delegate calls.
     It only handle delegate calls if there is at least 1 data source and all the data sources can handle the size delegate calls.

     - returns: `false` if there is no data sources or any of the data sources cannot handle size delegate calls.
     */
    public override func ds_shouldConsumeItemSizeDelegateCalls() -> Bool {
        if dataSources.isEmpty {
            return false
        }
        // if all data sources should consume item size delegates
        return dataSources.filter { $0.ds_shouldConsumeItemSizeDelegateCalls() }.count == dataSources.count
    }

    // MARK: Cell

    /**
     Asks the data source to return the number of sections.

     `1` for Single Section.
     `dataSources.count` for Multi section.

     - returns: The number of sections.
     */
    public override func ds_numberOfSections() -> Int {
        return collection.numberOfSections()
    }

    /**
     Asks the data source to return the number of items in a given section.

     - parameter section: An index number identifying a section.

     - returns: The number of items in a given section
     */
    public override func ds_numberOfItems(inSection section: Int) -> Int {
        return collection.numberOfItems(inSection: section)
    }

    /**
     Asks the data source for a cell to insert in a particular location of the general collection view.

     - parameter collectionView: A general collection view object requesting the cell.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: An object conforming to ReusableCell that the view can use for the specified item.
     */
    public override func ds_collectionView(collectionView: GeneralCollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> ReusableCell {

        let mapping = collection.collectionViewWrapperFromIndexPath(indexPath, collectionView: collectionView)
        return mapping.dataSource.ds_collectionView(mapping.wrapperView, cellForItemAtIndexPath: mapping.localIndexPath)
    }

    // MARK: Size

    /**
     Asks the data source for the size of a cell in a particular location of the general collection view.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: The size of the cell in a given location. For `UITableView`, the width is ignored.
     */
    public override func ds_collectionView(collectionView: GeneralCollectionView, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        let mapping = collection.collectionViewWrapperFromIndexPath(indexPath, collectionView: collectionView)
        return mapping.dataSource.ds_collectionView?(mapping.wrapperView, sizeForItemAtIndexPath: mapping.localIndexPath) ?? CGSize.zero
    }

    // MARK: Selection

    /**
     Asks the delegate if the specified item should be highlighted.
     `true` if the item should be highlighted or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be highlighted or `false` if it should not.
     */
    public override func ds_collectionView(collectionView: GeneralCollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let mapping = collection.collectionViewWrapperFromIndexPath(indexPath, collectionView: collectionView)
        return mapping.dataSource.ds_collectionView(mapping.wrapperView, shouldHighlightItemAtIndexPath: mapping.localIndexPath)
    }

    /**
     Tells the delegate that the specified item was highlighted.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */

    public override func ds_collectionView(collectionView: GeneralCollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let mapping = collection.collectionViewWrapperFromIndexPath(indexPath, collectionView: collectionView)
        return mapping.dataSource.ds_collectionView(mapping.wrapperView, didHighlightItemAtIndexPath: mapping.localIndexPath)
    }

    /**
     Tells the delegate that the highlight was removed from the item at the specified index path.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    public override func ds_collectionView(collectionView: GeneralCollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let mapping = collection.collectionViewWrapperFromIndexPath(indexPath, collectionView: collectionView)
        return mapping.dataSource.ds_collectionView(collectionView, didUnhighlightItemAtIndexPath: mapping.localIndexPath)
    }

    /**
     Asks the delegate if the specified item should be selected.
     `true` if the item should be selected or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be selected or `false` if it should not.
     */
    public override func ds_collectionView(collectionView: GeneralCollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let mapping = collection.collectionViewWrapperFromIndexPath(indexPath, collectionView: collectionView)
        return mapping.dataSource.ds_collectionView(collectionView, shouldSelectItemAtIndexPath: mapping.localIndexPath)
    }

    /**
     Tells the delegate that the specified item was selected.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    public override func ds_collectionView(collectionView: GeneralCollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let mapping = collection.collectionViewWrapperFromIndexPath(indexPath, collectionView: collectionView)
        return mapping.dataSource.ds_collectionView(mapping.wrapperView, didSelectItemAtIndexPath: mapping.localIndexPath)
    }

    /**
     Asks the delegate if the specified item should be deselected.
     `true` if the item should be deselected or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be deselected or `false` if it should not.
     */
    public override func ds_collectionView(collectionView: GeneralCollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let mapping = collection.collectionViewWrapperFromIndexPath(indexPath, collectionView: collectionView)
        return mapping.dataSource.ds_collectionView(collectionView, shouldDeselectItemAtIndexPath: mapping.localIndexPath)
    }

    /**
     Tells the delegate that the specified item was deselected.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    public override func ds_collectionView(collectionView: GeneralCollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let mapping = collection.collectionViewWrapperFromIndexPath(indexPath, collectionView: collectionView)
        return mapping.dataSource.ds_collectionView(mapping.wrapperView, didDeselectItemAtIndexPath: mapping.localIndexPath)
    }
}
