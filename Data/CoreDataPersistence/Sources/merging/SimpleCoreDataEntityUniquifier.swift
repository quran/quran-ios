//
//  SimpleCoreDataEntityUniquifier.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/6/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import SystemDependencies
import VLogging

public struct SimpleCoreDataEntityUniquifier<T: NSManagedObject>: CoreDataEntityUniquifier {
    // MARK: Lifecycle

    public init<Key: CoreDataKey>(sortBy: Key, ascending: Bool, key: Key) {
        sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: ascending)]
        predicate = { $0.predicate(equals: key) }
    }

    public init(sortDescriptors: [NSSortDescriptor], predicate: @escaping (T) -> NSPredicate) {
        self.sortDescriptors = sortDescriptors
        self.predicate = predicate
    }

    // MARK: Public

    public func merge(
        transactions: [PersistentHistoryTransaction],
        using taskContext: NSManagedObjectContext
    ) throws {
        let insertedEntitiesRetriever = CoreDataInsertedEntitiesRetriever<T>()
        let newEntitiesObjectIds = insertedEntitiesRetriever.insertedEntities(transactions: transactions)
        logger.notice("[CoreData] \(newEntitiesObjectIds.count) new \(T.self) inserted")

        for objectId in newEntitiesObjectIds {
            if let duplicates = try findDuplicates(of: objectId, using: taskContext) {
                delete(duplicates, using: taskContext)
            }
        }
        // Save the background context to trigger a notification and merge the result into the viewContext.
        try taskContext.save(with: "Deduplicating \(T.entity().name ?? "")")
    }

    // MARK: Private

    private let sortDescriptors: [NSSortDescriptor]
    private let predicate: (T) -> NSPredicate

    private func findDuplicates(of objectID: NSManagedObjectID, using context: NSManagedObjectContext) throws -> [NSManagedObject]? {
        guard let managedObject = context.object(with: objectID) as? T else {
            return nil
        }
        let fetchRequest = fetchRequestDuplicating(managedObject)
        let duplicatedEntities = try context.fetch(fetchRequest)
        guard duplicatedEntities.count > 1 else {
            return nil
        }
        let duplicatesToDelete = Array(duplicatedEntities.dropFirst())
        return duplicatesToDelete
    }

    private func fetchRequestDuplicating(_ managedObject: T) -> NSFetchRequest<T> {
        let fetchRequest = NSFetchRequest<T>(entityName: T.entity().name!)
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate(managedObject)
        return fetchRequest
    }

    private func delete(_ duplicatesToDelete: [NSManagedObject], using context: NSManagedObjectContext) {
        for entity in duplicatesToDelete {
            context.delete(entity)
        }
    }
}
