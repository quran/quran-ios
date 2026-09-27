//
//  CoreDataStack+Extensions.swift
//
//
//  Created by Mohamed Afifi on 2023-05-30.
//

import CoreData
import CoreDataModel
import CoreDataPersistence
import SystemDependenciesFake

extension CoreDataStack {
    public static func testingStack() -> CoreDataStack {
        CoreDataStack(name: "TestApp", modelUrl: CoreDataModelResources.quranModel, lazyUniquifiers: { [] })
    }

    /// Runs `body` on a new background context and saves it.
    public func write(_ body: (NSManagedObjectContext) throws -> Void) throws {
        let context = newBackgroundContext()
        try context.performAndWait {
            try body(context)
            try context.save()
        }
    }
}

extension PersistentHistoryChangeFake {
    public init(object: NSManagedObject, changeType: NSPersistentHistoryChangeType) {
        self.init(changedObjectID: object.objectID, changeType: changeType)
    }
}
