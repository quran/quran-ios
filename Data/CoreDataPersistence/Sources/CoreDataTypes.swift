//
//  CoreDataTypes.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/1/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import Foundation

public protocol CoreDataKey {
    var rawValue: String { get }
}

public extension NSSortDescriptor {
    convenience init(key: CoreDataKey, ascending: Bool) {
        self.init(key: key.rawValue, ascending: ascending)
    }
}

public extension NSManagedObject {
    func predicate<Key: CoreDataKey>(equals keys: Key...) -> NSPredicate {
        predicateIfValuesExist(equals: keys) ?? NSPredicate(value: false)
    }
}

extension NSManagedObject {
    func predicateIfValuesExist<Key: CoreDataKey>(equals keys: Key...) -> NSPredicate? {
        predicateIfValuesExist(equals: keys)
    }

    private func predicateIfValuesExist<Key: CoreDataKey>(equals keys: [Key]) -> NSPredicate? {
        let keysAndValues = keys.compactMap { key -> (Key, Any)? in
            guard let value = value(forKey: key.rawValue) else { return nil }
            return (key, value)
        }
        guard keysAndValues.count == keys.count else { return nil }
        return .init(equals: keysAndValues)
    }
}

public extension NSPredicate {
    convenience init<Key: CoreDataKey>(equals keysAndValues: (Key, Any)...) {
        self.init(equals: keysAndValues)
    }

    convenience init(equals keysAndValues: [(some CoreDataKey, Any)]) {
        let values = keysAndValues.map(\.1)
        let keysFormats = keysAndValues.map { "\($0.0.rawValue) == %@" }
        self.init(format: keysFormats.joined(separator: " AND "), argumentArray: values)
    }
}
