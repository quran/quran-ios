//
//  FileManager+ExtensionTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Foundation
import Utilities
import XCTest

final class FileManagerExtensionTests: XCTestCase {
    func test_availableCapacity_ofExistingDirectory_isPositive() throws {
        let capacity = try XCTUnwrap(FileManager.default.availableCapacity(at: FileManager.default.temporaryDirectory))

        XCTAssertGreaterThan(capacity, 0)
    }

    func test_availableCapacity_ofMissingDirectory_readsItsNearestExistingAncestor() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("audio_files/reciter", isDirectory: true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))

        let capacity = try XCTUnwrap(FileManager.default.availableCapacity(at: directory))

        XCTAssertGreaterThan(capacity, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }
}
