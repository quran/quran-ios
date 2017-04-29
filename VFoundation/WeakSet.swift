//
//  WeakSet.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/21/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation

/// While the `Element` can be any type including structs, enums. It only works with classes
/// This is because if we constrained `Element` to be `AnyObject`, we have to include a type-erasure for every protocol.
/// For example:
///
///     protocol Delegate: class {
///     }
///
///     // with WeakSet<Element>
///     // we can have
///     let delegates = WeakSet<Delegate>()
///
///     // with WeakSet<Element: AnyObject>
///     // we get the error, Using 'Delegate' as a concrete type conforming to protocol 'AnyObject' is not supported.
///     let delegates = WeakSet<Delegate>()
open class WeakSet<Element>: Sequence {

    public typealias Iterator = AnyIterator<Element>

    open var count: Int { return storage.count }

    private let storage = NSHashTable<AnyObject>.weakObjects()

    public init() { }

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
        return storage.contains(object as AnyObject)
    }

    open func makeIterator() -> Iterator {
        var arrayIterator = storage.allObjects.makeIterator()
        return AnyIterator {
            return arrayIterator.next() as? Element
        }
    }
}
