//
//  CoreDataPageBookmarkPersistence.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/8/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Combine
import CoreData
import CoreDataModel
import CoreDataPersistence
import Foundation
import PromiseKit
import QuranKit

public struct CoreDataPageBookmarkPersistence: PageBookmarkPersistence {
    private let context: NSManagedObjectContext

    public init(stack: CoreDataStack) {
        context = stack.newBackgroundContext()
    }

    public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        let request: NSFetchRequest<MO_PageBookmark> = MO_PageBookmark.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: Schema.PageBookmark.createdOn, ascending: false)]
        return CoreDataPublisher(request: request, context: context)
            .map { bookmarks in bookmarks.map { PageBookmarkPersistenceModel($0) } }
            .eraseToAnyPublisher()
    }

    public func insertPageBookmark(_ page: Int) -> Promise<Void> {
        context.perform { context in
            let newBookmark = MO_PageBookmark(context: context)
            newBookmark.createdOn = Date()
            newBookmark.modifiedOn = Date()
            newBookmark.page = Int32(page)

            try context.save(with: "insertPageBookmark")
        }
    }

    public func removePageBookmark(_ page: Int) -> Promise<Void> {
        context.perform { context in
            let request = fetchRequest(forPage: page)
            let bookmarks = try context.fetch(request)
            for bookmark in bookmarks {
                context.delete(bookmark)
            }
            try context.save(with: "removePageBookmark")
        }
    }

    private func fetchRequest(forPage page: Int) -> NSFetchRequest<MO_PageBookmark> {
        let request: NSFetchRequest<MO_PageBookmark> = MO_PageBookmark.fetchRequest()
        request.predicate = NSPredicate(equals: (Schema.PageBookmark.page, page))
        return request
    }
}

private extension PageBookmarkPersistenceModel {
    init(_ other: MO_PageBookmark) {
        creationDate = other.createdOn ?? Date()
        page = Int(other.page)
    }
}
