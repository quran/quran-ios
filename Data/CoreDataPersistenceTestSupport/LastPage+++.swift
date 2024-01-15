//
//  LastPage+++.swift
//
//
//  Created by Mohamed Afifi on 2023-05-30.
//

import CoreData
import CoreDataModel

extension NSManagedObjectContext {
    public func newLastPage(page: Int32, modifiedOn: TimeInterval) -> MO_LastPage {
        let object = MO_LastPage(context: self)
        object.page = page
        object.modifiedOn = Date(timeIntervalSince1970: modifiedOn)
        return object
    }

    public func allLastPages() throws -> [MO_LastPage] {
        let fetchRequest = MO_LastPage.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Schema.PageBookmark.modifiedOn, ascending: false)]
        return try fetch(fetchRequest)
    }
}
