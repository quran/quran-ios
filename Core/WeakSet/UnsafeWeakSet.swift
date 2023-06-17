//
//  UnsafeWeakSet.swift
//
//
//  Created by Mohamed Afifi on 2021-12-31.
//

import Foundation

open class UnsafeWeakSet<Element>: Sequence {
    public typealias Iterator = AnyIterator<Element>

    // MARK: Lifecycle

    public init() {}

    // MARK: Open

    open var count: Int { storage.count }

    open func insert(_ object: Element) {
        storage.add(object as AnyObject)
    }

    open func remove(_ object: Element) {
        storage.remove(object as AnyObject)
    }

    open func removeAllObjects() {
        storage.removeAllObjects()
    }

    open func contains(_ object: Element) -> Bool {
        storage.contains(object as AnyObject)
    }

    open func makeIterator() -> Iterator {
        var arrayIterator = storage.allObjects.makeIterator()
        return AnyIterator {
            arrayIterator.next() as? Element
        }
    }

    // MARK: Private

    private var storage = NSHashTable<AnyObject>.weakObjects()
}
