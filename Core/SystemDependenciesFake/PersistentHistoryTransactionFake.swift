//
//  PersistentHistoryTransactionFake.swift
//
//
//  Created by Mohamed Afifi on 2023-05-28.
//

import CoreData
import SystemDependencies

public struct PersistentHistoryChangeFake: PersistentHistoryChange {
    // MARK: Lifecycle

    public init(changedObjectID: NSManagedObjectID, changeType: NSPersistentHistoryChangeType) {
        self.changedObjectID = changedObjectID
        self.changeType = changeType
    }

    // MARK: Public

    public var changedObjectID: NSManagedObjectID
    public var changeType: NSPersistentHistoryChangeType
}

public struct PersistentHistoryTransactionFake: PersistentHistoryTransaction {
    // MARK: Lifecycle

    public init(historyChanges: [PersistentHistoryChange]) {
        self.historyChanges = historyChanges
    }

    // MARK: Public

    public var historyChanges: [PersistentHistoryChange]

    public func changes() -> [PersistentHistoryChange] {
        historyChanges
    }
}
