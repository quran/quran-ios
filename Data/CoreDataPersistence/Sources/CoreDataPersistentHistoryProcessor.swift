//
//  CoreDataPersistentHistoryProcessor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/5/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import VLogging

class CoreDataPersistentHistoryProcessor {
    // MARK: Lifecycle

    init(name: String, uniquifiers: [CoreDataEntityUniquifier]) {
        self.name = name
        trasactionsMerger = CoreDataPersistentHistoryTransactionsMerger(uniquifiers: uniquifiers)
    }

    // MARK: Internal

    /// Process persistent history, posting any relevant transactions to the current view.
    func processNewHistory(using taskContext: NSManagedObjectContext) {
        // Fetch history received from outside the app since the last token
        let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
        historyFetchRequest.predicate = NSPredicate(format: "author != %@", taskContext.transactionAuthor!)
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
        request.fetchRequest = historyFetchRequest

        do {
            let result = try taskContext.execute(request) as? NSPersistentHistoryResult
            guard let transactions = result?.result as? [NSPersistentHistoryTransaction] else { return }
            guard !transactions.isEmpty else { return }

            trasactionsMerger.merge(transactions: transactions, using: taskContext)

            // Update the history token using the last transaction.
            lastHistoryToken = transactions.last!.token
        } catch {
            logger.error("Failed to retrieve history with error '\(error)'")
        }
    }

    // MARK: Private

    private let name: String
    private let trasactionsMerger: CoreDataPersistentHistoryTransactionsMerger

    private lazy var tokenStore = CoreDataPersistentHistoryTokenStore(fileURL: {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(name, isDirectory: true)
        return url.appendingPathComponent("token.data", isDirectory: false)
    }())

    /// Track the last history token processed for a store, and write its value to file.
    ///
    /// The historyQueue reads the token when executing operations, and updates it after processing is complete.
    private lazy var lastHistoryToken: NSPersistentHistoryToken? = initialLastHistoryToken() {
        didSet {
            guard let token = lastHistoryToken else { return }
            tokenStore.save(token)
        }
    }

    private func initialLastHistoryToken() -> NSPersistentHistoryToken? {
        tokenStore.load()
    }
}
