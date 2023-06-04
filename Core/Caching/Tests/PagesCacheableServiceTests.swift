//
//  PagesCacheableServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-27.
//

import AsyncUtilitiesForTesting
@testable import Caching
import XCTest

struct TestPage: Pageable {
    var pageNumber: Int

    var next: TestPage {
        TestPage(pageNumber: pageNumber + 1)
    }

    var previous: TestPage {
        TestPage(pageNumber: pageNumber - 1)
    }
}

class PagesCacheableServiceTests: XCTestCase {
    var cache: Cache<TestPage, Int>!
    var pagesCacheableService: PagesCacheableService<TestPage, Int>!

    override func setUp() {
        super.setUp()

        cache = Cache<TestPage, Int>()
        let pages = (1 ... 10).map { TestPage(pageNumber: $0) }

        pagesCacheableService = PagesCacheableService(
            cache: cache,
            previousPagesCount: 2,
            nextPagesCount: 2,
            pages: pages,
            operation: { page in
                // Mock operation: Returns the square of the page number
                page.pageNumber * page.pageNumber
            }
        )
    }

    override func tearDown() {
        pagesCacheableService = nil
        cache = nil
        super.tearDown()
    }

    func testGet() async throws {
        let page = TestPage(pageNumber: 5)

        // Call get operation
        let result = try await pagesCacheableService.get(page)
        XCTAssertEqual(result, 25, "Result should be the square of the page number.")

        // Assert next values are preloaded
        await Task.megaYield()
        XCTAssertEqual(cache.object(forKey: page.next), 36)
        XCTAssertEqual(cache.object(forKey: page.next.next), 49)
        XCTAssertNil(cache.object(forKey: page.next.next.next))

        // Assert previous values are preloaded
        XCTAssertEqual(cache.object(forKey: page.previous), 16)
        XCTAssertEqual(cache.object(forKey: page.previous.previous), 9)
        XCTAssertNil(cache.object(forKey: page.previous.previous.previous))
    }

    func testGetFirstItem() async throws {
        let page = TestPage(pageNumber: 1)

        // Call get operation
        let result = try await pagesCacheableService.get(page)
        XCTAssertEqual(result, 1, "Result should be the square of the page number.")

        // Assert next values are preloaded
        await Task.megaYield()
        XCTAssertEqual(cache.object(forKey: page.next), 4)
        XCTAssertEqual(cache.object(forKey: page.next.next), 9)
        XCTAssertNil(cache.object(forKey: page.next.next.next))

        // Assert previous values are not preloaded
        XCTAssertNil(cache.object(forKey: page.previous))
    }

    func testGetLastItem() async throws {
        let page = TestPage(pageNumber: 10)

        // Call get operation
        let result = try await pagesCacheableService.get(page)
        XCTAssertEqual(result, 100, "Result should be the square of the page number.")

        // Assert next values are preloaded
        await Task.megaYield()
        XCTAssertNil(cache.object(forKey: page.next))

        // Assert previous values are preloaded
        XCTAssertEqual(cache.object(forKey: page.previous), 81)
        XCTAssertEqual(cache.object(forKey: page.previous.previous), 64)
        XCTAssertNil(cache.object(forKey: page.previous.previous.previous))
    }

    func testGetCached() {
        let page = TestPage(pageNumber: 5)
        let object = 31

        // Set a cached object
        cache.setObject(object, forKey: page)

        // Get the cached object
        let cachedObject = pagesCacheableService.getCached(page)

        XCTAssertEqual(cachedObject, object, "Cached object should be the same as the set object.")
    }

    func testInvalidate() {
        let page = TestPage(pageNumber: 5)
        let object = 45

        // Set a cached object
        cache.setObject(object, forKey: page)

        // Invalidate the service
        pagesCacheableService.invalidate()

        // Get the cached object
        let cachedObject = pagesCacheableService.getCached(page)

        XCTAssertNil(cachedObject, "Cached object should be nil after invalidate.")
    }
}
