//
//  CoreDataLastPagePersistence.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/1/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Combine
import CoreData
import CoreDataModel
import CoreDataPersistence
import Foundation
import QuranKit

public final class CoreDataLastPagePersistence: LastPagePersistence {
    // MARK: Lifecycle

    public init(stack: CoreDataStack) {
        context = stack.newBackgroundContext()
    }

    // MARK: Public

    public func lastPages() -> AnyPublisher<[LastPagePersistenceModel], Never> {
        let request: NSFetchRequest<MO_LastPage> = MO_LastPage.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: Schema.LastPage.modifiedOn, ascending: false)]
        return CoreDataPublisher(request: request, context: context)
            .map { lastPages in
                lastPages.prefix(Self.maxNumberOfLastPages).compactMap { LastPagePersistenceModel($0) }
            }
            .eraseToAnyPublisher()
    }

    public func retrieveAll() async throws -> [LastPagePersistenceModel] {
        try await context.perform { context in
            let request: NSFetchRequest<MO_LastPage> = MO_LastPage.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: Schema.LastPage.modifiedOn, ascending: false)]
            let lastPages = try context.fetch(request)
            return lastPages.prefix(Self.maxNumberOfLastPages).compactMap { LastPagePersistenceModel($0) }
        }
    }

    public func add(at page: Page) async throws -> LastPagePersistenceModel {
        try await context.perform { context in
            try self.add(at: page, using: context)
        }
    }

    public func update(
        pages: Set<Page>,
        to destination: Page
    ) async throws -> LastPagePersistenceModel {
        try await context.perform { context in
            let sourcePages = try self.fetch(pages: pages, using: context)

            // Insert the destination if none of the grouped source rows still exist.
            guard let existingPage = sourcePages.max(by: {
                ($0.modifiedOn ?? .distantPast) < ($1.modifiedOn ?? .distantPast)
            }) else {
                return try self.add(at: destination, using: context)
            }

            // Collapse every source row and any existing destination row into the newest source row.
            let destinationPages = try self.fetch(pages: [destination], using: context)
            for lastPage in Set(sourcePages + destinationPages) {
                if lastPage != existingPage {
                    context.delete(lastPage)
                }
            }

            existingPage.page = Int32(destination.pageNumber)
            existingPage.mushafID = destination.quran.pageMushaf.rawValue
            let modifiedOn = Date()
            existingPage.modifiedOn = modifiedOn
            try context.save(with: "Update LastPage")
            return LastPagePersistenceModel(
                page: destination,
                createdOn: existingPage.createdOn ?? Date(),
                modifiedOn: modifiedOn
            )
        }
    }

    // MARK: Private

    private static let maxNumberOfLastPages = 3

    private let context: NSManagedObjectContext
    private let overflowHandler = CoreDataLastPageOverflowHandler()

    private func add(
        at page: Page,
        using context: NSManagedObjectContext
    ) throws -> LastPagePersistenceModel {
        for lastPage in try fetch(pages: [page], using: context) {
            context.delete(lastPage)
        }

        // Insert the new page.
        let newLastPage = MO_LastPage(context: context)
        let createdOn = Date()
        let modifiedOn = Date()
        newLastPage.createdOn = createdOn
        newLastPage.modifiedOn = modifiedOn
        newLastPage.mushafID = page.quran.pageMushaf.rawValue
        newLastPage.page = Int32(page.pageNumber)

        try context.save(with: "Add LastPage")

        // remove overflow
        try overflowHandler.removeOverflowIfneeded(using: context)
        return LastPagePersistenceModel(
            page: page,
            createdOn: createdOn,
            modifiedOn: modifiedOn
        )
    }

    private func fetch(
        pages: Set<Page>,
        using context: NSManagedObjectContext
    ) throws -> [MO_LastPage] {
        guard !pages.isEmpty else { return [] }
        let request: NSFetchRequest<MO_LastPage> = MO_LastPage.fetchRequest()
        request.predicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: pages.map { page in
                NSPredicate(
                    equals:
                    (Schema.LastPage.page, page.pageNumber),
                    (Schema.LastPage.mushafID, page.quran.pageMushaf.rawValue)
                )
            }
        )
        return try context.fetch(request)
    }
}

private extension LastPagePersistenceModel {
    init?(_ other: MO_LastPage) {
        let mushaf = QuranPageMushaf(rawValue: other.mushafID) ?? .madani1405
        guard let page = Page(quran: mushaf.quran, pageNumber: Int(other.page)) else {
            return nil
        }
        self.init(
            page: page,
            createdOn: other.createdOn ?? Date(),
            modifiedOn: other.modifiedOn ?? Date()
        )
    }
}
