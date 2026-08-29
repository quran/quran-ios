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
import QuranKit

public struct CoreDataPageBookmarkPersistence: PageBookmarkPersistence {
    // MARK: Lifecycle

    public init(stack: CoreDataStack) {
        context = stack.newBackgroundContext()
    }

    // MARK: Public

    public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        let request: NSFetchRequest<MO_PageBookmark> = MO_PageBookmark.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: Schema.PageBookmark.createdOn, ascending: false)]
        return CoreDataPublisher(request: request, context: context)
            .map { bookmarks in bookmarks.compactMap { PageBookmarkPersistenceModel($0) } }
            .eraseToAnyPublisher()
    }

    public func insertPageBookmark(at page: Page) async throws {
        try await context.perform { context in
            let newBookmark = MO_PageBookmark(context: context)
            newBookmark.createdOn = Date()
            newBookmark.modifiedOn = Date()
            newBookmark.mushafID = page.quran.pageMushaf.rawValue
            newBookmark.page = Int32(page.pageNumber)

            try context.save(with: "insertPageBookmark")
        }
    }

    public func removePageBookmarks(at pages: Set<Page>) async throws {
        guard !pages.isEmpty else { return }
        try await context.perform { context in
            let request = fetchRequest(for: pages)
            let bookmarks = try context.fetch(request)
            for bookmark in bookmarks {
                context.delete(bookmark)
            }
            try context.save(with: "removePageBookmark")
        }
    }

    public func removeAllPageBookmarks() async throws {
        try await context.perform { context in
            let request: NSFetchRequest<MO_PageBookmark> = MO_PageBookmark.fetchRequest()
            let bookmarks = try context.fetch(request)
            for bookmark in bookmarks {
                context.delete(bookmark)
            }
            try context.save(with: "removeAllPageBookmarks")
        }
    }

    // MARK: Private

    private let context: NSManagedObjectContext

    private func fetchRequest(for pages: Set<Page>) -> NSFetchRequest<MO_PageBookmark> {
        let request: NSFetchRequest<MO_PageBookmark> = MO_PageBookmark.fetchRequest()
        request.predicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: pages.map { page in
                NSPredicate(
                    equals:
                    (Schema.PageBookmark.page, page.pageNumber),
                    (Schema.PageBookmark.mushafID, page.quran.pageMushaf.rawValue)
                )
            }
        )
        return request
    }
}

private extension PageBookmarkPersistenceModel {
    init?(_ other: MO_PageBookmark) {
        let mushaf = QuranPageMushaf(rawValue: other.mushafID) ?? .madani1405
        guard let page = Page(quran: mushaf.quran, pageNumber: Int(other.page)) else {
            return nil
        }
        self.page = page
        creationDate = other.createdOn ?? Date()
    }
}
