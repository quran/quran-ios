//
//  AnyBasicDataSourceRepresentable.swift
//  GenericDataSource
//
//  Created by Mohamed Ebrahim Mohamed Afifi on 3/20/17.
//  Copyright © 2017 mohamede1945. All rights reserved.
//

import Foundation

private class _AnyBasicDataSourceRepresentableBoxBase<Item>: BasicDataSourceRepresentable {

    var items: [Item] {
        get { fatalError() }
        set { fatalError() }
    }

    var dataSource: AbstractDataSource { fatalError() }
    var onItemsUpdated: (([Item]) -> Void)? {
        get { fatalError() }
        set { fatalError() }
    }
}

private class _AnyBasicDataSourceRepresentableBox<DS: BasicDataSourceRepresentable>: _AnyBasicDataSourceRepresentableBoxBase<DS.Item> {

    private let ds: DS
    init(ds: DS) {
        self.ds = ds
    }

    override var items: [DS.Item] {
        get { return ds.items }
        set { ds.items = newValue }
    }

    override var dataSource: AbstractDataSource { return ds.dataSource }

    override var onItemsUpdated: (([DS.Item]) -> Void)? {
        get { return ds.onItemsUpdated }
        set { ds.onItemsUpdated = newValue }
    }
}

/// Represents a type-erased `BasicDataSourceRepresentable` type.
public final class AnyBasicDataSourceRepresentable<Item>: BasicDataSourceRepresentable {

    private let box: _AnyBasicDataSourceRepresentableBoxBase<Item>

    /// Creates new instance with the passed `BasicDataSourceRepresentable` to erase its type.
    ///
    /// - Parameter ds: The instance that will have its type erased.
    public init<DS: BasicDataSourceRepresentable>(_ ds: DS) where DS.Item == Item {
        box = _AnyBasicDataSourceRepresentableBox(ds: ds)
    }

    /// Represents the underlying data source.
    public var dataSource: AbstractDataSource { return box.dataSource }

    /// Represents the list of items that is managed by this data source.
    public var items: [Item] {
        get { return box.items }
        set { box.items = newValue }
    }

    public var onItemsUpdated: (([Item]) -> Void)? {
        get { return box.onItemsUpdated }
        set { box.onItemsUpdated = newValue }
    }
}

extension BasicDataSourceRepresentable {

    /// Convert the instance into a `AnyBasicDataSourceRepresentable`.
    ///
    /// - Returns: The converted `AnyBasicDataSourceRepresentable`.
    public func asBasicDataSourceRepresentable() -> AnyBasicDataSourceRepresentable<Item> {
        return AnyBasicDataSourceRepresentable(self)
    }
}
