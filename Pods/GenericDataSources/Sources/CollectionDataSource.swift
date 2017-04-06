//
//  CollectionDataSource.swift
//  GenericDataSource
//
//  Created by Mohamed Ebrahim Mohamed Afifi on 3/21/17.
//  Copyright © 2017 mohamede1945. All rights reserved.
//

/// Represents the collection data source used as
public protocol CollectionDataSource: DataSource {

    /// The list of the children datasources.
    var dataSources: [DataSource] { get }

    /**
     Adds a new data source to the list of children data sources.

     - parameter dataSource: The new data source to add.
     */
    func add(_ dataSource: DataSource)

    /**
     Inserts the data source to the list of children data sources at specific index.

     - parameter dataSource: The new data source to add.
     - parameter index:      The index to insert the new data source at.
     */
    func insert(_ dataSource: DataSource, at index: Int)

    /**
     Removes a data source from the children data sources list.

     - parameter dataSource: The data source to remove.
     */
    func remove(_ dataSource: DataSource)

    /// Removes data source at the specified index.
    ///
    /// - Parameter index: The index of the data source to remove.
    /// - Returns: The removed data source.
    @discardableResult
    func remove(at index: Int) -> DataSource

    /// Clear the collection of data sources.
    func removeAllDataSources()

    /**
     Returns the data source at certain index.

     - parameter index: The index of the data source to return.

     - returns: The data source at specified index.
     */
    func dataSource(at index: Int) -> DataSource

    /**
     Check if a data source exists or not.

     - parameter dataSource: The data source to check.

     - returns: `true``, if the data source exists. Otherwise `false`.
     */
    func contains(_ dataSource: DataSource) -> Bool

    /**
     Gets the index of a data source or `nil` if not exist.

     - parameter dataSource: The data source to get the index for.

     - returns: The index of the data source.
     */
    func index(of dataSource: DataSource) -> Int?

    // MARK: - IndexPath and Section translations

    /**
     Converts a section value relative to a specific data source to a section value relative to the composite data source.

     - parameter section:       The local section relative to the passed data source.
     - parameter dataSource:    The data source that is the local section is relative to it. Should be a child data source.

     - returns: The global section relative to the composite data source.
     */
    func globalSectionForLocalSection(_ section: Int, dataSource: DataSource) -> Int

    /**
     Converts a section value relative to the composite data source to a section value relative to a specific data source.

     - parameter section:    The section relative to the compsite data source.
     - parameter dataSource: The data source that is the returned local section is relative to it. Should be a child data source.

     - returns: The global section relative to the composite data source.
     */
    func localSectionForGlobalSection(_ section: Int, dataSource: DataSource) -> Int

    /**
     Converts an index path value relative to a specific data source to an index path value relative to the composite data source.

     - parameter indexPath:     The local index path relative to the passed data source.
     - parameter dataSource:    The data source that is the local index path is relative to it. Should be a child data source.

     - returns: The global index path relative to the composite data source.
     */
    func globalIndexPathForLocalIndexPath(_ indexPath: IndexPath, dataSource: DataSource) -> IndexPath

    /**
     Converts an index path value relative to the composite data source to an index path value relative to a specific data source.

     - parameter indexPath:    The index path relative to the compsite data source.
     - parameter dataSource: The data source that is the returned local index path is relative to it. Should be a child data source.

     - returns: The global index path relative to the composite data source.
     */
    func localIndexPathForGlobalIndexPath(_ indexPath: IndexPath, dataSource: DataSource) -> IndexPath
}
