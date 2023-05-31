//
//  PageBookmarkEntity.swift
//
//
//  Created by Mohamed Afifi on 2023-05-30.
//

import CoreData
import CoreDataModel
import Foundation

public struct PageBookmarkEntity: TestingEntity {
    public let page: Int32
    public let modifiedOn: Date
    public let object: MO_PageBookmark
    public init(context: NSManagedObjectContext, page: Int32, modifiedOn: TimeInterval) {
        self.page = page
        self.modifiedOn = Date(timeIntervalSince1970: modifiedOn)
        object = MO_PageBookmark(context: context)
        object.page = page
        object.modifiedOn = Date(timeIntervalSince1970: modifiedOn)
    }
}

extension NSManagedObjectContext {
    public func allPageBookmarks() throws -> [MO_PageBookmark] {
        let fetchRequest = MO_PageBookmark.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Schema.PageBookmark.modifiedOn, ascending: true)]
        return try fetch(fetchRequest)
    }
}
