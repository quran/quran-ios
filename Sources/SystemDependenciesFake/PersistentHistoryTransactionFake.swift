//
//  PersistentHistoryTransactionFake.swift
//
//
//  Created by Mohamed Afifi on 2023-05-28.
//

import CoreData
import SystemDependencies

public struct PersistentHistoryChangeFake: PersistentHistoryChange {
    public var changedObjectID: NSManagedObjectID
    public var changeType: NSPersistentHistoryChangeType
    public init(changedObjectID: NSManagedObjectID, changeType: NSPersistentHistoryChangeType) {
        self.changedObjectID = changedObjectID
        self.changeType = changeType
    }
}

public struct PersistentHistoryTransactionFake: PersistentHistoryTransaction {
    public var historyChanges: [PersistentHistoryChange]

    public init(historyChanges: [PersistentHistoryChange]) {
        self.historyChanges = historyChanges
    }

    public func changes() -> [PersistentHistoryChange] {
        historyChanges
    }
}
