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
            .map { lastPages in lastPages.prefix(Self.maxNumberOfLastPages).map { LastPagePersistenceModel($0) } }
            .eraseToAnyPublisher()
    }

    public func retrieveAll() async throws -> [LastPagePersistenceModel] {
        try await context.perform { context in
            let request: NSFetchRequest<MO_LastPage> = MO_LastPage.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: Schema.LastPage.modifiedOn, ascending: false)]
            let lastPages = try context.fetch(request)
            return lastPages.prefix(Self.maxNumberOfLastPages).map { LastPagePersistenceModel($0) }
        }
    }

    public func add(page: Int) async throws -> LastPagePersistenceModel {
        try await context.perform { context in
            try self.add(page: page, using: context)
        }
    }

    public func update(page oldPage: Int, toPage newPage: Int) async throws -> LastPagePersistenceModel {
        try await context.perform { context in
            // delete newPage, so we can replace it
            try self.delete(page: newPage, using: context)

            // get existing old page
            let request: NSFetchRequest<MO_LastPage> = MO_LastPage.fetchRequest()
            request.predicate = NSPredicate(equals: (Schema.LastPage.page, oldPage))
            let lastPages = try context.fetch(request)

            // insert new page if no old page
            guard let existingPage = lastPages.first else {
                return try self.add(page: newPage, using: context)
            }

            // update
            existingPage.page = Int32(newPage)
            existingPage.modifiedOn = Date()
            try context.save(with: "Update LastPage")
            return LastPagePersistenceModel(existingPage)
        }
    }

    // MARK: Private

    private static let maxNumberOfLastPages = 3

    private let context: NSManagedObjectContext
    private let overflowHandler = CoreDataLastPageOverflowHandler()

    private func add(page: Int, using context: NSManagedObjectContext) throws -> LastPagePersistenceModel {
        try delete(page: page, using: context)

        // insert new page
        let newLastPage = MO_LastPage(context: context)
        newLastPage.createdOn = Date()
        newLastPage.modifiedOn = Date()
        newLastPage.page = Int32(page)

        try context.save(with: "Add LastPage")

        // remove overflow
        try overflowHandler.removeOverflowIfneeded(using: context)
        return LastPagePersistenceModel(newLastPage)
    }

    private func delete(page: Int, using context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<MO_LastPage> = MO_LastPage.fetchRequest()
        request.predicate = NSPredicate(equals: (Schema.LastPage.page, page))
        let lastPages = try context.fetch(request)
        for lastPage in lastPages {
            context.delete(lastPage)
        }
    }
}

private extension LastPagePersistenceModel {
    init(_ other: MO_LastPage) {
        self.init(
            page: Int(other.page),
            createdOn: other.createdOn ?? Date(),
            modifiedOn: other.modifiedOn ?? Date()
        )
    }
}
