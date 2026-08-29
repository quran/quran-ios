//
//  CoreDataPageBookmarkUniquifier.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/8/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import CoreData
import CoreDataModel
import CoreDataPersistence

public typealias CoreDataPageBookmarkUniquifier = SimpleCoreDataEntityUniquifier<MO_PageBookmark>
extension CoreDataPageBookmarkUniquifier {
    public init() {
        self.init(
            sortDescriptors: [NSSortDescriptor(key: Schema.PageBookmark.modifiedOn, ascending: false)],
            predicate: { $0.predicate(equals: Schema.PageBookmark.page, .mushafID) }
        )
    }
}
