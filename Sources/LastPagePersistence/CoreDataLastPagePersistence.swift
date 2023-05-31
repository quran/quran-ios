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
import PromiseKit
import Utilities

public final class CoreDataLastPagePersistence: LastPagePersistence {
    private static let maxNumberOfLastPages = 3

    private let context: NSManagedObjectContext
    private let overflowHandler = CoreDataLastPageOverflowHandler()

    public init(stack: CoreDataStack) {
        context = stack.newBackgroundContext()
    }

    public func lastPages() -> AnyPublisher<[LastPageDTO], Never> {
        let request: NSFetchRequest<MO_LastPage> = MO_LastPage.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: Schema.LastPage.modifiedOn, ascending: false)]
        return CoreDataPublisher(request: request, context: context)
            .map { lastPages in lastPages.prefix(Self.maxNumberOfLastPages).map { LastPageDTO($0) } }
            .eraseToAnyPublisher()
    }

    public func retrieveAll() -> Promise<[LastPageDTO]> {
        context.perform { context in
            let request: NSFetchRequest<MO_LastPage> = MO_LastPage.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: Schema.LastPage.modifiedOn, ascending: false)]
            let lastPages = try context.fetch(request)
            return lastPages.prefix(Self.maxNumberOfLastPages).map { LastPageDTO($0) }
        }
    }

    // TODO: Remove the following code
    func add(_ lastPages: [LastPageDTO]) -> Promise<Void> {
        guard !lastPages.isEmpty else {
            return .value(())
        }
        return context.perform { context in
            for lastPage in lastPages {
                // insert new page
                let newLastPage = MO_LastPage(context: context)
                newLastPage.createdOn = lastPage.createdOn
                newLastPage.modifiedOn = lastPage.modifiedOn
                newLastPage.page = Int32(lastPage.page)
            }
            try context.save(with: "Add Multiple LastPage")
        }
    }

    public func add(page: Int) -> Promise<LastPageDTO> {
        context.perform { context in
            try self.add(page: page, using: context)
        }
    }

    private func add(page: Int, using context: NSManagedObjectContext) throws -> LastPageDTO {
        try delete(page: page, using: context)

        // insert new page
        let newLastPage = MO_LastPage(context: context)
        newLastPage.createdOn = Date()
        newLastPage.modifiedOn = Date()
        newLastPage.page = Int32(page)

        try context.save(with: "Add LastPage")

        // remove overflow
        try overflowHandler.removeOverflowIfneeded(using: context)
        return LastPageDTO(newLastPage)
    }

    public func update(page oldPage: Int, toPage newPage: Int) -> Promise<LastPageDTO> {
        context.perform { context in
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
            return LastPageDTO(existingPage)
        }
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

private extension LastPageDTO {
    init(_ other: MO_LastPage) {
        self.init(page: Int(other.page),
                  createdOn: other.createdOn ?? Date(),
                  modifiedOn: other.modifiedOn ?? Date())
    }
}
