//
//  CoreDataCompletionPersistence.swift
//
//
//  Created by Selim on 29.03.2026.
//

import Combine
import CoreData
import CoreDataModel
import CoreDataPersistence
import Foundation

public struct CoreDataCompletionPersistence: CompletionPersistence {
    // MARK: Lifecycle

    public init(stack: CoreDataStack) {
        context = stack.newBackgroundContext()
    }

    // MARK: Public

    public func completions() -> AnyPublisher<[CompletionPersistenceModel], Never> {
        let request: NSFetchRequest<MO_Completion> = MO_Completion.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: Schema.Completion.startedAt, ascending: false)]
        return CoreDataPublisher(request: request, context: context)
            .map { completions in completions.map { CompletionPersistenceModel($0) } }
            .eraseToAnyPublisher()
    }

    public func insertCompletion(_ model: CompletionPersistenceModel) async throws {
        try await context.perform { context in
            let entity = MO_Completion(context: context)
            entity.id = model.id
            entity.name = model.name
            entity.quranId = model.quranId
            entity.startedAt = model.startedAt
            entity.finishedAt = model.finishedAt
            entity.isActive = model.isActive
            try context.save(with: "insertCompletion")
        }
    }

    public func updateCompletion(_ model: CompletionPersistenceModel) async throws {
        try await context.perform { context in
            let request = fetchRequest(forId: model.id)
            let results = try context.fetch(request)
            guard let entity = results.first else { return }
            entity.name = model.name
            entity.quranId = model.quranId
            entity.startedAt = model.startedAt
            entity.finishedAt = model.finishedAt
            entity.isActive = model.isActive
            try context.save(with: "updateCompletion")
        }
    }

    public func deleteCompletion(id: UUID) async throws {
        try await context.perform { context in
            // Delete all associated CompletionBookmarks
            let bookmarkRequest = fetchBookmarkRequest(forCompletionId: id)
            let bookmarks = try context.fetch(bookmarkRequest)
            for bookmark in bookmarks {
                context.delete(bookmark)
            }

            // Delete the completion
            let request = fetchRequest(forId: id)
            let completions = try context.fetch(request)
            for completion in completions {
                context.delete(completion)
            }

            try context.save(with: "deleteCompletion")
        }
    }

    public func setActive(id: UUID) async throws {
        try await context.perform { context in
            // Deactivate all completions
            let allRequest: NSFetchRequest<MO_Completion> = MO_Completion.fetchRequest()
            let all = try context.fetch(allRequest)
            for entity in all {
                entity.isActive = false
            }

            // Activate the target
            let request = fetchRequest(forId: id)
            if let entity = try context.fetch(request).first {
                entity.isActive = true
            }

            try context.save(with: "setActive")
        }
    }

    public func completionBookmarks(completionId: UUID) -> AnyPublisher<[CompletionBookmarkPersistenceModel], Never> {
        let request: NSFetchRequest<MO_CompletionBookmark> = MO_CompletionBookmark.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: Schema.CompletionBookmark.createdAt, ascending: false)]
        request.predicate = NSPredicate(format: "\(Schema.CompletionBookmark.completionId.rawValue) == %@", completionId as CVarArg)
        return CoreDataPublisher(request: request, context: context)
            .map { bookmarks in bookmarks.map { CompletionBookmarkPersistenceModel($0) } }
            .eraseToAnyPublisher()
    }

    public func allCompletionBookmarks() -> AnyPublisher<[CompletionBookmarkPersistenceModel], Never> {
        let request: NSFetchRequest<MO_CompletionBookmark> = MO_CompletionBookmark.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: Schema.CompletionBookmark.createdAt, ascending: false)]
        return CoreDataPublisher(request: request, context: context)
            .map { bookmarks in bookmarks.map { CompletionBookmarkPersistenceModel($0) } }
            .eraseToAnyPublisher()
    }

    public func insertCompletionBookmark(_ model: CompletionBookmarkPersistenceModel) async throws {
        try await context.perform { context in
            let entity = MO_CompletionBookmark(context: context)
            entity.id = model.id
            entity.completionId = model.completionId
            entity.page = Int32(model.page)
            entity.createdAt = model.createdAt
            try context.save(with: "insertCompletionBookmark")
        }
    }

    public func detachCompletionBookmark(id: UUID) async throws {
        try await context.perform { context in
            let request: NSFetchRequest<MO_CompletionBookmark> = MO_CompletionBookmark.fetchRequest()
            request.predicate = NSPredicate(format: "\(Schema.CompletionBookmark.id.rawValue) == %@", id as CVarArg)
            let bookmarks = try context.fetch(request)
            for bookmark in bookmarks {
                context.delete(bookmark)
            }
            try context.save(with: "detachCompletionBookmark")
        }
    }

    // MARK: Private

    private let context: NSManagedObjectContext

    private func fetchRequest(forId id: UUID) -> NSFetchRequest<MO_Completion> {
        let request: NSFetchRequest<MO_Completion> = MO_Completion.fetchRequest()
        request.predicate = NSPredicate(format: "\(Schema.Completion.id.rawValue) == %@", id as CVarArg)
        return request
    }

    private func fetchBookmarkRequest(forCompletionId completionId: UUID) -> NSFetchRequest<MO_CompletionBookmark> {
        let request: NSFetchRequest<MO_CompletionBookmark> = MO_CompletionBookmark.fetchRequest()
        request.predicate = NSPredicate(format: "\(Schema.CompletionBookmark.completionId.rawValue) == %@", completionId as CVarArg)
        return request
    }
}

private extension CompletionPersistenceModel {
    init(_ other: MO_Completion) {
        id = other.id ?? UUID()
        name = other.name
        quranId = other.quranId ?? ""
        startedAt = other.startedAt ?? Date()
        finishedAt = other.finishedAt
        isActive = other.isActive
    }
}

private extension CompletionBookmarkPersistenceModel {
    init(_ other: MO_CompletionBookmark) {
        id = other.id ?? UUID()
        completionId = other.completionId ?? UUID()
        page = Int(other.page)
        createdAt = other.createdAt ?? Date()
    }
}
