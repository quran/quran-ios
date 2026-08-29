//
//  PageBookmark+++.swift
//
//
//  Created by Mohamed Afifi on 2023-05-30.
//

import CoreData
import CoreDataModel
import Foundation

extension NSManagedObjectContext {
    public func newPageBookmark(
        page: Int32,
        mushafID: Int16 = 0,
        modifiedOn: TimeInterval
    ) -> MO_PageBookmark {
        let object = MO_PageBookmark(context: self)
        object.page = page
        object.mushafID = mushafID
        object.modifiedOn = Date(timeIntervalSince1970: modifiedOn)
        return object
    }

    public func allPageBookmarks() throws -> [MO_PageBookmark] {
        let fetchRequest = MO_PageBookmark.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Schema.PageBookmark.modifiedOn, ascending: true)]
        return try fetch(fetchRequest)
    }
}
