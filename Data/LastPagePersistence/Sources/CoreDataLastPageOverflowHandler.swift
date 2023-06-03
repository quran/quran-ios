//
//  CoreDataLastPageOverflowHandler.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/7/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import CoreDataModel

struct CoreDataLastPageOverflowHandler {
    private static let maxNumberOfLastPages = 3

    func removeOverflowIfneeded(using context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<MO_LastPage> = MO_LastPage.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: Schema.LastPage.modifiedOn, ascending: false)]
        let lastPages = try context.fetch(request)

        // remove old pages up to (total - maxNumberOfLastPages)
        if lastPages.count > Self.maxNumberOfLastPages {
            for i in Self.maxNumberOfLastPages ..< lastPages.count {
                context.delete(lastPages[i])
            }
        }
        try context.save(with: "Deleting overflow LastPages")
    }
}
