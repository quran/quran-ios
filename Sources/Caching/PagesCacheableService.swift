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

import Foundation
import PromiseKit

public protocol Pageable: Hashable {
    var pageNumber: Int { get }
}

public class PagesCacheableService<Input: Pageable, Output> {
    public typealias Page = Input

    private let previousPagesCount: Int
    private let nextPagesCount: Int
    private let pages: [Page]

    private let service: OperationCacheableService<Input, Output>

    public init(cache: Cache<Input, Output>,
                previousPagesCount: Int,
                nextPagesCount: Int,
                pages: [Page],
                operation: @escaping (Input) -> Promise<Output>)
    {
        service = OperationCacheableService(cache: cache, operation: operation)
        self.pages = pages
        self.nextPagesCount = nextPagesCount
        self.previousPagesCount = previousPagesCount
    }

    public func invalidate() {
        service.invalidate()
    }

    public func get(_ page: Page) -> Promise<Output> {
        defer {
            // schedule for closer pages
            cachePagesCloserToPage(page)
        }

        // preload requested page with very high priority and QoS
        return preload(page)
    }

    public func getCached(_ input: Page) -> Output? {
        service.getCached(input)
    }

    private func cachePagesCloserToPage(_ page: Page) {
        func cacheCloser(_ pageNumber: Int) {
            if let page = pages.first(where: { $0.pageNumber == pageNumber }) {
                _ = preload(page)
            }
        }

        // load next pages
        for index in 0 ..< nextPagesCount {
            cacheCloser(page.pageNumber + 1 + index)
        }

        // load previous pages
        for index in 0 ..< previousPagesCount {
            cacheCloser(page.pageNumber - 1 - index)
        }
    }

    private func preload(_ page: Page) -> Promise<Output> {
        service.get(page)
    }
}
