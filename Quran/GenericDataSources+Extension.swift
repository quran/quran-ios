//
//  GenericDataSources+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/18/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

protocol BasicDataSourceRepresentable: class {
    associatedtype Item
    var items: [Item] { get set }
    var datasource: AbstractDataSource { get }
}

private class _AnyBasicDataSourceRepresentableBoxBase<Item>: BasicDataSourceRepresentable {

    var items: [Item] {
        get { fatalError() }
        set { fatalError() }
    }

    var datasource: AbstractDataSource { fatalError() }
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

    override var datasource: AbstractDataSource { return ds.datasource }
}

class AnyBasicDataSourceRepresentable<Item>: BasicDataSourceRepresentable {

    private let box: _AnyBasicDataSourceRepresentableBoxBase<Item>
    init<DS: BasicDataSourceRepresentable>(_ ds: DS) where DS.Item == Item {
        box = _AnyBasicDataSourceRepresentableBox(ds: ds)
    }

    var items: [Item] {
        get { return box.items }
        set { box.items = newValue }
    }

    var datasource: AbstractDataSource { return box.datasource }
}

extension BasicDataSourceRepresentable {
    func item(at indexPath: IndexPath) -> Item {
        return items[indexPath.item]
    }
}

extension BasicDataSourceRepresentable where Item : Equatable {

    /**
     Gets the index path for a certain item.

     - parameter item: The item that is being checked.

     - returns: The index path for a certain item, or `nil` if there is no such item.
     */
    func indexPath(for item: Item) -> IndexPath? {
        return items.index(of: item).flatMap { IndexPath(item: $0, section: 0) }
    }
}

extension BasicDataSourceRepresentable {
    func asBasicDataSourceRepresentable() -> AnyBasicDataSourceRepresentable<Item> {
        return AnyBasicDataSourceRepresentable(self)
    }
}

extension BasicDataSource: BasicDataSourceRepresentable {
    var datasource: AbstractDataSource { return self }
}
