//
//  PagesCacheableService.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/21/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import PromiseKit

private func operationQueue() -> OperationQueue {
    let queue = OperationQueue()
    queue.name = "com.operation.pages-cacheable-service"
    return queue
}

open class PagesCacheableService<Output>: CacheableService {

    private let previousPagesCount: Int
    private let nextPagesCount: Int
    private let range: CountableClosedRange<Int>

    private let service: OperationCacheableService<Int, Output>

    public init(queue              : OperationQueue = operationQueue(),
                cache              : Cache<Int, Output>,
                previousPagesCount : Int,
                nextPagesCount     : Int,
                pageRange          : CountableClosedRange<Int>,
                operationCreator   : AnyCreator<Int, AnyPreloadingOperationRepresentable<Output>>) {
        service = OperationCacheableService(queue: queue, cache: cache, operationCreator: operationCreator)
        self.range              = pageRange
        self.nextPagesCount     = nextPagesCount
        self.previousPagesCount = previousPagesCount
    }

    open func invalidate() {
        service.invalidate()
    }

    open func get(_ page: Int) -> Promise<Output> {
        defer {
            // schedule for closer pages
            cachePagesCloserToPage(page)
        }

        // preload requested page with very high priority and QoS
        return preload(page)
    }

    open func getCached(_ input: Int) -> Output? {
        return service.getCached(input)
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

    private func preload(_ page: Int) -> Promise<Output> {
        guard range.contains(page) else {
            fatalError("page '\(page)' is out of the range \(range)")
        }
        return service.get(page)
    }
}
