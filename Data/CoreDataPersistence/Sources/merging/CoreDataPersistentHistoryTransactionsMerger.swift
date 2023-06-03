//
//  CoreDataPersistentHistoryTransactionsMerger.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/5/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import SystemDependencies
import VLogging

struct CoreDataPersistentHistoryTransactionsMerger {
    private let uniquifiers: [CoreDataEntityUniquifier]
    init(uniquifiers: [CoreDataEntityUniquifier]) {
        self.uniquifiers = uniquifiers
    }

    func merge(transactions: [PersistentHistoryTransaction], using taskContext: NSManagedObjectContext) {
        for uniquifier in uniquifiers {
            do {
                try uniquifier.merge(transactions: transactions, using: taskContext)
            } catch {
                logger.error("Error trying to merge transactions by \(type(of: uniquifier)). Error: \(error)")
                taskContext.reset()
            }
        }
    }
}
