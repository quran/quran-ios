//
//  OperationCacheableServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-27.
//

@testable import Caching
import TestUtilities
import XCTest

class OperationCacheableServiceTests: XCTestCase {
    let key = 1234
    let object = 1945

    var cache: Cache<Int, Int>!
    var operationCacheableService: OperationCacheableService<Int, Int>!

    override func setUp() {
        super.setUp()
        cache = Cache<Int, Int>()
        operationCacheableService = OperationCacheableService(cache: cache, operation: { key in
            // Mock operation, which just doubles the integer value of the key
            key * 2
        })
    }

    override func tearDown() {
        operationCacheableService = nil
        cache = nil
        super.tearDown()
    }

    func testGetOperation() async throws {
        // Call get operation
        let result = try await operationCacheableService.get(key)

        XCTAssertEqual(result, 2468, "Result should be double the value of the key.")
    }

    func testGetCached() {
        // Set a cached object
        cache.setObject(object, forKey: key)

        // Get the cached object
        let cachedObject = operationCacheableService.getCached(key)

        XCTAssertEqual(cachedObject, object, "Cached object should be the same as the set object.")
    }

    func testInvalidate() {
        // Set a cached object
        cache.setObject(object, forKey: key)

        // Invalidate the service
        operationCacheableService.invalidate()

        // Get the cached object
        let cachedObject = operationCacheableService.getCached(key)

        XCTAssertNil(cachedObject, "Cached object should be nil after invalidate.")
    }
}
