//
//  CoreDataInsertedEntitiesRetriever.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/6/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import SystemDependencies

public struct CoreDataInsertedEntitiesRetriever<T: NSManagedObject> {
    public init() { }

    public func insertedEntities(transactions: [PersistentHistoryTransaction]) -> [NSManagedObjectID] {
        var newEntityObjectIDs = [NSManagedObjectID]()
        let entityName = T.entity().name
        for transaction in transactions {
            for change in transaction.changes() {
                if change.changedObjectID.entity.name == entityName && change.changeType == .insert {
                    newEntityObjectIDs.append(change.changedObjectID)
                }
            }
        }
        return newEntityObjectIDs
    }
}
