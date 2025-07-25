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
import Shared

public struct CoreDataPageBookmarkPersistence: PageBookmarkPersistence {
    // MARK: Lifecycle

    private let sharedRepo: PageBookmarksRepository

    public init(stack: CoreDataStack) {
        context = stack.newBackgroundContext()
        sharedRepo = PageBookmarksRepositoryFactory.companion.createRepository(driverFactory: DriverFactory.init())
    }

    // MARK: Public

    public func pageBookmarks() -> AnyPublisher<[PageBookmarkPersistenceModel], Never> {
        print("Returning a publisher")
        return sharedRepo.getAllBookmarks()
            .asPublisher(first: [])
            .map { (bookmarks: [Shared.PageBookmark]) -> [PageBookmarkPersistenceModel] in
                bookmarks.map {
                    PageBookmarkPersistenceModel(page: Int($0.page),
                                                 creationDate: Date(timeIntervalSince1970: TimeInterval($0.lastUpdated)))
                }
            }
            .catch { error in
                //                logger.error("Error in page bookmarks publisher: \(error)")
                return Empty<[PageBookmarkPersistenceModel], Never>()
            }
            .eraseToAnyPublisher()
//        let request: NSFetchRequest<MO_PageBookmark> = MO_PageBookmark.fetchRequest()
//        request.sortDescriptors = [NSSortDescriptor(key: Schema.PageBookmark.createdOn, ascending: false)]
//        return CoreDataPublisher(request: request, context: context)
//            .map { bookmarks in bookmarks.map { PageBookmarkPersistenceModel($0) } }
//            .eraseToAnyPublisher()
    }

    public func insertPageBookmark(_ page: Int) async throws {
        try await sharedRepo.addPageBookmark(page: Int32(page))
        self.notify()
//        try await context.perform { context in
//            let newBookmark = MO_PageBookmark(context: context)
//            newBookmark.createdOn = Date()
//            newBookmark.modifiedOn = Date()
//            newBookmark.page = Int32(page)
//
//            try context.save(with: "insertPageBookmark")
//        }
    }

    public func removePageBookmark(_ page: Int) async throws {
        try await sharedRepo.deletePageBookmark(page: Int32(page))
        self.notify()
//        try await context.perform { context in
//            let request = fetchRequest(forPage: page)
//            let bookmarks = try context.fetch(request)
//            for bookmark in bookmarks {
//                context.delete(bookmark)
//            }
//            try context.save(with: "removePageBookmark")
//        }
    }

    private func notify() {
        NotificationCenter.default
            .post(name: NSNotification.Name.init("bookmarksupdated"), object: nil)
    }

    // MARK: Private

    private let context: NSManagedObjectContext

//    private func fetchRequest(forPage page: Int) -> NSFetchRequest<MO_PageBookmark> {
//        let request: NSFetchRequest<MO_PageBookmark> = MO_PageBookmark.fetchRequest()
//        request.predicate = NSPredicate(equals: (Schema.PageBookmark.page, page))
//        return request
//    }
}

private extension PageBookmarkPersistenceModel {
    init(_ other: MO_PageBookmark) {
        creationDate = other.createdOn ?? Date()
        page = Int(other.page)
    }
}


extension Kotlinx_coroutines_coreFlow {
    func asPublisher<T>(first: T) -> AnyPublisher<T, Error> {
        let subject = CurrentValueSubject<T, Error>(first)
//
//        let job = collect(collector: { value in
//            subject.send(value as! T)
//            return KotlinUnit()
//        }) { error in
//            if let error = error {
//                subject.send(completion: .failure(error))
//            } else {
//                subject.send(completion: .finished)
//            }
//        }

        let collector = Collector<T>(subject: subject)

        collect(collector: collector,
                completionHandler: { error in
            if let error = error {
                subject.send(completion: .failure(error))
            } else {
                subject.send(completion: .finished)
            }
        })

        return subject
            .handleEvents(receiveCancel: {
                // ?
            })
            .eraseToAnyPublisher()
    }
}

private class Collector<T>: NSObject, Kotlinx_coroutines_coreFlowCollector {

    let subject: any Subject<T, Error>

    init(subject: any Subject<T, Error>) {
        self.subject = subject
    }

    func emit(value: Any?, completionHandler: @escaping ((any Error)?) -> Void) {
        print("Got values: \(value ?? [])")
        subject.send(value as! T)
    }
    
//    func emit(value: Any?) async throws {
//        <#code#>
//    }
}
