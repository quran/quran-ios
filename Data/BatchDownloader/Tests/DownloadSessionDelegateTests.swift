//
//  DownloadSessionDelegateTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Foundation
import XCTest
@testable import BatchDownloader

final class DownloadSessionDelegateTests: XCTestCase {
    func test_availableCapacity_ofMissingDirectory_readsItsNearestExistingAncestor() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("audio_files/reciter", isDirectory: true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))

        let capacity = try XCTUnwrap(DownloadSessionDelegate.availableCapacity(at: directory))
        XCTAssertGreaterThan(capacity, 0)
    }
}
