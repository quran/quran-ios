//
//  CoreDataEntityUniquifier.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/6/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import SystemDependencies

public protocol CoreDataEntityUniquifier {
    func merge(transactions: [PersistentHistoryTransaction], using taskContext: NSManagedObjectContext) throws
}
