//
//  WeakSet.swift
//
//
//  Created by Mohamed Afifi on 2021-12-31.
//

import Foundation
import Locking

/// Thread safe set holding weak references to its elements.
///
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

    // MARK: Lifecycle

    public init() {}

    // MARK: Open

    open var count: Int { storage.value.count }

    open func insert(_ object: Element) {
        storage.sync { (s: inout NSHashTable<AnyObject>) in
            s.add(object as AnyObject)
        }
    }

    open func remove(_ object: Element) {
        storage.sync { (s: inout NSHashTable<AnyObject>) in
            s.remove(object as AnyObject)
        }
    }

    open func removeAllObjects() {
        storage.sync { (s: inout NSHashTable<AnyObject>) in
            s.removeAllObjects()
        }
    }

    open func contains(_ object: Element) -> Bool {
        storage.sync { (s: inout NSHashTable<AnyObject>) in
            s.contains(object as AnyObject)
        }
    }

    open func makeIterator() -> Iterator {
        storage.sync { (s: inout NSHashTable<AnyObject>) in
            var arrayIterator = s.allObjects.makeIterator()
            return AnyIterator {
                arrayIterator.next() as? Element
            }
        }
    }

    // MARK: Private

    private var storage = Protected<NSHashTable<AnyObject>>(.weakObjects())
}
