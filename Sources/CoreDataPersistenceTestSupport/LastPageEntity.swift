//
//  LastPageEntity.swift
//
//
//  Created by Mohamed Afifi on 2023-05-30.
//

import CoreData
import CoreDataModel

public struct LastPageEntity: TestingEntity {
    public let page: Int32
    public let modifiedOn: Date
    public let object: MO_LastPage
    public init(context: NSManagedObjectContext, page: Int32, modifiedOn: TimeInterval) {
        self.page = page
        self.modifiedOn = Date(timeIntervalSince1970: modifiedOn)
        object = MO_LastPage(context: context)
        object.page = page
        object.modifiedOn = Date(timeIntervalSince1970: modifiedOn)
    }
}

extension NSManagedObjectContext {
    public func allLastPages() throws -> [MO_LastPage] {
        let fetchRequest = MO_LastPage.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Schema.PageBookmark.modifiedOn, ascending: false)]
        return try fetch(fetchRequest)
    }
}
