//
//  CoreDataNoteUniquifier.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/6/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import CoreDataModel
import CoreDataPersistence
import SystemDependencies
import VLogging

public struct CoreDataNoteUniquifier: CoreDataEntityUniquifier {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func merge(transactions: [PersistentHistoryTransaction], using taskContext: NSManagedObjectContext) throws {
        // Ensure there is at least one note change in the transactions
        guard transactions.contains(where: { transaction in
            transaction.changes().contains { change in
                change.changedObjectID.entity == MO_Note.entity()
            }
        }) else {
            return
        }

        logger.notice("[CoreData] Finding \(MO_Note.self) with no associated verses.")
        let notesToDelete = try findNotesWithNoVerses(using: taskContext)
        logger.notice("[CoreData] Found \(notesToDelete.count) \(MO_Note.self) with no associated verses.")
        removeNotes(notesToDelete, using: taskContext)

        // Save the background context to trigger a notification and merge the result into the viewContext.
        try taskContext.save(with: "Deduplicating \(String(describing: MO_Note.entity().name))")
    }

    // MARK: Private

    private func findNotesWithNoVerses(using context: NSManagedObjectContext) throws -> [MO_Note] {
        let fetchRequest = MO_Note.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "verses.@count == 0")
        return try context.fetch(fetchRequest)
    }

    private func removeNotes(_ notes: [MO_Note], using context: NSManagedObjectContext) {
        for note in notes {
            // delete the note
            context.delete(note)
        }
    }
}
