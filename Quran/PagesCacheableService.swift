//
//  PagesCacheableService.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/21/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import PromiseKit

private func operationQueue() -> OperationQueue {
    let queue = OperationQueue()
    queue.name = "com.operation.pages-cacheable-service"
    return queue
}

class PagesCacheableService<Output, OperationType: PreloadingOperationRepresentable>: CacheableService
    where OperationType.Output == Output {

    private let previousPagesCount: Int
    private let nextPagesCount: Int
    private let range: CountableClosedRange<Int>

    private let service: OperationCacheableService<Int, Output, OperationType>

    init(queue              : OperationQueue = operationQueue(),
         cache              : Cache<Int, Output>,
         previousPagesCount : Int,
         nextPagesCount     : Int,
         pageRange          : CountableClosedRange<Int>,
         operationCreator   : AnyCreator<OperationType, Int>) {
        service = OperationCacheableService(queue: queue, cache: cache, operationCreator: operationCreator)
        self.range              = pageRange
        self.nextPagesCount     = nextPagesCount
        self.previousPagesCount = previousPagesCount
    }

    func invalidate() {
        service.invalidate()
    }

    func get(_ page: Int) -> Promise<Output> {
        defer {
            // schedule for closer pages
            cachePagesCloserToPage(page)
        }

        // preload requested page with very high priority and QoS
        return preload(page)
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

    func preload(_ page: Int) -> Promise<Output> {
        guard range.contains(page) else {
            fatalError("page '\(page)' is out of the range \(range)")
        }
        return service.get(page)
    }
}
