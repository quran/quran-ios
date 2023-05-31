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
}

extension PersistentHistoryChangeFake {
    public init(object: NSManagedObject, changeType: NSPersistentHistoryChangeType) {
        self.init(changedObjectID: object.objectID, changeType: changeType)
    }

    public init(entity: some TestingEntity, changeType: NSPersistentHistoryChangeType) {
        self.init(object: entity.object, changeType: changeType)
    }
}
