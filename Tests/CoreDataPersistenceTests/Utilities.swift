//
//  Utilities.swift
//
//
//  Created by Mohamed Afifi on 2023-05-28.
//

import CoreData
import CoreDataModel
import CoreDataPersistence
import SystemDependenciesFake

extension CoreDataStack {
    static func testingStack() -> CoreDataStack {
        CoreDataStack(name: "TestApp", modelUrl: Resources.quranModel, lazyUniquifiers: { [] })
    }
}

extension NSManagedObjectContext {
    func allPageBookmarks() throws -> [MO_PageBookmark] {
        let fetchRequest = MO_PageBookmark.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Schema.PageBookmark.modifiedOn, ascending: true)]
        return try fetch(fetchRequest)
    }
}

protocol Entity<T> {
    associatedtype T: NSManagedObject
    var object: T { get }
}

struct PageBookmarkEntity: Entity {
    let page: Int32
    let modifiedOn: Date
    let object: MO_PageBookmark
    init(context: NSManagedObjectContext, page: Int32, modifiedOn: TimeInterval) {
        self.page = page
        self.modifiedOn = Date(timeIntervalSince1970: modifiedOn)
        object = MO_PageBookmark(context: context)
        object.page = page
        object.modifiedOn = Date(timeIntervalSince1970: modifiedOn)
    }
}

extension PersistentHistoryChangeFake {
    init(object: NSManagedObject, changeType: NSPersistentHistoryChangeType) {
        self.init(changedObjectID: object.objectID, changeType: changeType)
    }

    init(entity: some Entity, changeType: NSPersistentHistoryChangeType) {
        self.init(object: entity.object, changeType: changeType)
    }
}
