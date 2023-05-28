//
//  CoreDataPersistentHistoryProcessor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/5/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import VLogging

@available(iOS 13.0, *)
class CoreDataPersistentHistoryProcessor {
    private let name: String
    private let trasactionsMerger: CoreDataPersistentHistoryTransactionsMerger

    /**
     Track the last history token processed for a store, and write its value to file.

     The historyQueue reads the token when executing operations, and updates it after processing is complete.
     */
    private lazy var lastHistoryToken: NSPersistentHistoryToken? = initialLastHistoryToken() {
        didSet {
            guard let token = lastHistoryToken,
                  let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else { return }

            do {
                try data.write(to: tokenFile)
            } catch {
                logger.error("###\(#function): Failed to write token data. Error = \(error)")
            }
        }
    }

    private func initialLastHistoryToken() -> NSPersistentHistoryToken? {
        // Load the last token from the token file.
        if let tokenData = try? Data(contentsOf: tokenFile) {
            do {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
            } catch {
                logger.error("###\(#function): Failed to unarchive NSPersistentHistoryToken. Error = \(error)")
            }
        }
        return nil
    }

    /**
      The file URL for persisting the persistent history token.
     */
    private lazy var tokenFile: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(name, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                logger.error("###\(#function): Failed to create persistent container URL. Error = \(error)")
            }
        }
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()

    init(name: String, uniquifiers: [CoreDataEntityUniquifier]) {
        self.name = name
        trasactionsMerger = CoreDataPersistentHistoryTransactionsMerger(uniquifiers: uniquifiers)
    }

    /**
     Process persistent history, posting any relevant transactions to the current view.
     */
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
}
