//
//  CacheTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-27.
//

@testable import Caching
import XCTest

class CacheTests: XCTestCase {
    let key1 = "TestKey1"
    let object1 = 1234

    let key2 = "TestKey2"
    let object2 = 5678

    var cache: Cache<String, Int>!

    override func setUp() {
        super.setUp()
        cache = Cache<String, Int>()
    }

    override func tearDown() {
        cache = nil
        super.tearDown()
    }

    func testSetObject_and_objectForKey() {
        // set object for key
        cache.setObject(object1, forKey: key1)

        // check if object is correctly retrieved
        XCTAssertEqual(object1, cache.object(forKey: key1))
    }

    func testRemoveObject() {
        // set object for key
        cache.setObject(object1, forKey: key1)

        // remove object for key
        cache.removeObject(forKey: key1)

        // check if object is correctly removed
        XCTAssertNil(cache.object(forKey: key1), "The object should be removed from the cache.")
    }

    func testRemoveAllObjects() {
        // set objects for keys
        cache.setObject(object1, forKey: key1)
        cache.setObject(object2, forKey: key2)

        // remove all objects
        cache.removeAllObjects()

        // check if all objects are correctly removed
        XCTAssertNil(cache.object(forKey: key1), "All objects should be removed from the cache.")
        XCTAssertNil(cache.object(forKey: key2), "All objects should be removed from the cache.")
    }
}
