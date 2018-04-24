//
//  BasicDataSourceRepresentable.swift
//  GenericDataSource
//
//  Created by Mohamed Ebrahim Mohamed Afifi on 3/20/17.
//  Copyright © 2017 mohamede1945. All rights reserved.
//

import Foundation

/// Represents a protocol for basic data sources that manages list of items.
/// Sometimes we need to work with BasicDataSource regardless of the cell type.
/// For example:
///
///     let dataSource1 = BasicDataSource<String, TextCollectionViewCell>(reuseIdentifier: "cell1")
///     let dataSource2 = BasicDataSource<String, DifferentCollectionViewCell>(reuseIdentifier: "cell2")
///     let dsRepresentable1: AnyBasicDataSourceRepresentable<String> = dataSource1.asBasicDataSourceRepresentable()
///     let dsRepresentable2: AnyBasicDataSourceRepresentable<String> = dataSource2.asBasicDataSourceRepresentable()
///     let representables = [dsRepresentable1, dsRepresentable2]
///     // representables is an array that doesn't care about the cell only the items.
public protocol BasicDataSourceRepresentable: class {
    associatedtype Item

    /// Represents the underlying data source.
    var dataSource: AbstractDataSource { get }

    /// Represents the list of items that is managed by this data source.
    var items: [Item] { get set }

    /// A closure to be called when the items array has been updated.
    var onItemsUpdated: (([Item]) -> Void)? { get set }
}

extension BasicDataSourceRepresentable {

    /**
     Gets the item at the specified index path.

     **IMPORTANT* This method assumes that the `indexPath` is a local value. In other words, value of (0 0) returns first one. Value of (1 0) returns the second one even if the `BasicDataSource` is part of a `CompositeDataSource`.

     - parameter indexPath: The index path parameter, the section value is ignored.

     - returns: The item at a certain index path.
     */
    public func item(at indexPath: IndexPath) -> Item {
        return items[indexPath.item]
    }

    /**
     Replaces an item at a certain index path.

     **IMPORTANT* This method assumes that the `indexPath` is a local value. In other words, value of (0 0) replaces the first one. Value of (1 0) replaces the second one even if the `BasicDataSource` is part of a `CompositeDataSource`.

     - parameter indexPath:  The index path parameter, the section value is ignored.
     - parameter item:      The new item that will be saved in the `items` array.
     */
    public func replaceItem(at indexPath: IndexPath, with item: Item) {
        items[indexPath.item] = item
    }
}

extension BasicDataSourceRepresentable where Item: Equatable {

    /**
     Gets the index path for a certain item.
     - parameter item: The item that is being checked.
     - returns: The index path for a certain item, or `nil` if there is no such item.
     */
    public func indexPath(for item: Item) -> IndexPath? {
        return items.index(of: item).flatMap { IndexPath(item: $0, section: 0) }
    }
}
