//
//  PagesCacheableService.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/21/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit
import PromiseKit

class PagesCacheableService<Output, OperationType: PreloadingOperationRepresentable>: CacheableService
    where OperationType.Output == Output {

    private let previousPagesCount: Int
    private let nextPagesCount: Int
    private let range: CountableClosedRange<Int>

    private let cache: Cache<Int, Output>

    private let queue = OperationQueue()
    private var inProgressOperations: [Int: OperationType] = [:]
    private let lock = NSLock()

    private let operationCreator: AnyCreator<OperationType, Int>

    init(cache              : Cache<Int, Output>,
         previousPagesCount : Int,
         nextPagesCount     : Int,
         pageRange          : CountableClosedRange<Int>,
         operationCreator   : AnyCreator<OperationType, Int>) {
        self.range              = pageRange
        self.cache              = cache
        self.nextPagesCount     = nextPagesCount
        self.operationCreator   = operationCreator
        self.previousPagesCount = previousPagesCount
    }

    func invalidate() {
        queue.cancelAllOperations()
        inProgressOperations.removeAll()
        cache.removeAllObjects()
    }

    func get(_ page: Int) -> Promise<Output> {
        defer {
            // schedule for closer pages
            cachePagesCloserToPage(page)
        }

        // preload requested page with very high priority and QoS
        return preload(page, priority: .veryHigh, qualityOfService: .userInitiated)
    }

    private func cachePagesCloserToPage(_ page: Int) {
        func cacheCloser(_ page: Int) {
            if range.contains(page) {
                preload(page).suppress()
            }
        }

        // load next pages
        for index in 0..<nextPagesCount {
            cacheCloser(page + 1 + index)
        }

        // load previous pages
        for index in 0..<previousPagesCount {
            cacheCloser(page - 1 - index)
        }
    }

    func preload(_ page: Int,
                 priority: Operation.QueuePriority = .normal,
                 qualityOfService: QualityOfService = .background) -> Promise<Output> {
        guard range.contains(page) else {
            fatalError("page '\(page)' is out of the range \(Quran.QuranPagesRange)")
        }

        return lock.execute { () -> Promise<Output> in

            if let result = cache.object(forKey: page) {
                return Promise(value: result)
            } else  if let operation = inProgressOperations[page] {
                return operation.promise
            } else {

                // create the operation
                let operation = operationCreator.create(page)
                // add it to the in progress
                inProgressOperations[page] = operation

                // cache the result
                let promise = operation.promise
                    .then(on: .global()) { result -> Output in
                        self.lock.execute {
                            self.cache.setObject(result, forKey: page)
                            // remove from in progress
                            self.inProgressOperations.removeValue(forKey: page)
                        }
                        return result
                }

                operation.operation.qualityOfService = qualityOfService
                operation.operation.queuePriority = priority
                queue.addOperation(operation.operation)
                return promise
            }
        }
    }
}
