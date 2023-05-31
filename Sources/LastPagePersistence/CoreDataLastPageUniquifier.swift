//
//  CoreDataLastPageUniquifier.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/7/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import CoreDataModel
import CoreDataPersistence
import SystemDependencies

public struct CoreDataLastPageUniquifier: CoreDataEntityUniquifier {
    private let overflowHandler = CoreDataLastPageOverflowHandler()

    private let simpleUniquifier = SimpleCoreDataEntityUniquifier<MO_LastPage>(
        sortBy: Schema.LastPage.modifiedOn,
        ascending: false,
        key: .page
    )

    public init() {
    }

    public func merge(transactions: [PersistentHistoryTransaction], using taskContext: NSManagedObjectContext) throws {
        // merge with existing ones
        try simpleUniquifier.merge(transactions: transactions, using: taskContext)

        if hasLastPageChanges(transactions) {
            // remove overflow
            try overflowHandler.removeOverflowIfneeded(using: taskContext)
        }
    }

    private func hasLastPageChanges(_ transactions: [PersistentHistoryTransaction]) -> Bool {
        let entityName = MO_LastPage.entity().name
        return transactions.contains { transaction in
            transaction.changes().contains { change in
                change.changedObjectID.entity.name == entityName
            }
        }
    }
}
