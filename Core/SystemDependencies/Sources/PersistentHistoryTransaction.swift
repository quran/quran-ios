//
//  PersistentHistoryTransaction.swift
//
//
//  Created by Mohamed Afifi on 2023-05-28.
//

import CoreData

public protocol PersistentHistoryChange {
    var changedObjectID: NSManagedObjectID { get }
    var changeType: NSPersistentHistoryChangeType { get }
}

public protocol PersistentHistoryTransaction {
    func changes() -> [PersistentHistoryChange]
}

extension NSPersistentHistoryChange: PersistentHistoryChange {}
extension NSPersistentHistoryTransaction: PersistentHistoryTransaction {
    public func changes() -> [PersistentHistoryChange] {
        changes ?? []
    }
}
