//
//  FileSystemErrorTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Foundation
import Utilities
import XCTest
@testable import BatchDownloader

final class FileSystemErrorTests: XCTestCase {
    // MARK: Internal

    func test_noSpaceLeftOnDevice_isNoDiskSpace() {
        XCTAssertTrue(FileSystemError.isNoDiskSpace(posixError(ENOSPC), availableCapacity: ampleCapacity))
    }

    func test_fileWriteOutOfSpace_isNoDiskSpace() {
        let error = CocoaError(.fileWriteOutOfSpace)
        XCTAssertTrue(FileSystemError.isNoDiskSpace(error, availableCapacity: ampleCapacity))
    }

    func test_noSpaceLeftOnDeviceUnderURLError_isNoDiskSpace() {
        let error = URLError(.unknown, userInfo: [NSUnderlyingErrorKey: posixError(ENOSPC)])
        XCTAssertTrue(FileSystemError.isNoDiskSpace(error, availableCapacity: ampleCapacity))
    }

    func test_noSuchFileWithAmpleCapacity_isNotNoDiskSpace() {
        XCTAssertFalse(FileSystemError.isNoDiskSpace(posixError(ENOENT), availableCapacity: ampleCapacity))
    }

    func test_noSuchFileWithLowCapacity_isNoDiskSpace() {
        XCTAssertTrue(FileSystemError.isNoDiskSpace(posixError(ENOENT), availableCapacity: lowCapacity))
    }

    func test_noSuchFileAtLowCapacityThreshold_isNotNoDiskSpace() {
        let capacity = FileManager.lowAvailableCapacity
        XCTAssertFalse(FileSystemError.isNoDiskSpace(posixError(ENOENT), availableCapacity: capacity))
    }

    func test_noSuchFileUnderCocoaErrorWithLowCapacity_isNoDiskSpace() {
        // FileManager.moveItem fails like this when the source is missing.
        let error = CocoaError(.fileNoSuchFile, userInfo: [NSUnderlyingErrorKey: posixError(ENOENT)])
        XCTAssertTrue(FileSystemError.isNoDiskSpace(error, availableCapacity: lowCapacity))
    }

    func test_noSuchFileWithUnknownCapacity_isNotNoDiskSpace() {
        XCTAssertFalse(FileSystemError.isNoDiskSpace(posixError(ENOENT), availableCapacity: nil))
    }

    func test_cannotWriteToFileWithLowCapacity_isNoDiskSpace() {
        let error = URLError(.cannotWriteToFile)
        XCTAssertTrue(FileSystemError.isNoDiskSpace(error, availableCapacity: lowCapacity))
    }

    func test_cannotCreateFileWithLowCapacity_isNoDiskSpace() {
        let error = URLError(.cannotCreateFile)
        XCTAssertTrue(FileSystemError.isNoDiskSpace(error, availableCapacity: lowCapacity))
    }

    func test_timedOutWithLowCapacity_isNotNoDiskSpace() {
        let error = URLError(.timedOut)
        XCTAssertFalse(FileSystemError.isNoDiskSpace(error, availableCapacity: lowCapacity))
    }

    func test_noSpaceCodeInAnotherDomain_isNotNoDiskSpace() {
        let error = NSError(domain: "OtherDomain", code: Int(ENOSPC))
        XCTAssertFalse(FileSystemError.isNoDiskSpace(error, availableCapacity: ampleCapacity))
    }

    func test_initWithNoSpaceLeftOnDeviceUnderCocoaError_isNoDiskSpace() {
        let error = CocoaError(.fileWriteUnknown, userInfo: [NSUnderlyingErrorKey: posixError(ENOSPC)])
        guard case .noDiskSpace = FileSystemError(error: error) else {
            return XCTFail("Expected noDiskSpace")
        }
    }

    // MARK: Private

    private let ampleCapacity = 10 * FileManager.lowAvailableCapacity
    private let lowCapacity = FileManager.lowAvailableCapacity - 1

    private func posixError(_ code: Int32) -> NSError {
        NSError(domain: NSPOSIXErrorDomain, code: Int(code))
    }
}
