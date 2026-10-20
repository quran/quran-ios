//
//  FileSystemErrorTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Foundation
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
        let capacity = FileSystemError.lowAvailableCapacity
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

    func test_noSpaceLeftOnDeviceAtUnderlyingErrorDepth_isNoDiskSpace() {
        // The last error the walk inspects.
        var error = posixError(ENOSPC)
        for _ in 0 ..< FileSystemError.maximumUnderlyingErrorDepth - 1 {
            error = NSError(domain: "OtherDomain", code: 1, userInfo: [NSUnderlyingErrorKey: error])
        }
        XCTAssertTrue(FileSystemError.isNoDiskSpace(error, availableCapacity: ampleCapacity))
    }

    func test_noSpaceLeftOnDeviceBeyondUnderlyingErrorDepth_isNotNoDiskSpace() {
        // NSError copies its user info, so a plain chain can't refer back to itself. The depth
        // cap bounds the walk, so an error nested deeper than it is never inspected.
        var error = posixError(ENOSPC)
        for _ in 0 ..< FileSystemError.maximumUnderlyingErrorDepth {
            error = NSError(domain: "OtherDomain", code: 1, userInfo: [NSUnderlyingErrorKey: error])
        }
        XCTAssertFalse(FileSystemError.isNoDiskSpace(error, availableCapacity: ampleCapacity))
    }

    func test_initWithNoSpaceLeftOnDeviceUnderCocoaError_isNoDiskSpace() {
        let error = CocoaError(.fileWriteUnknown, userInfo: [NSUnderlyingErrorKey: posixError(ENOSPC)])
        guard case .noDiskSpace = FileSystemError(error: error) else {
            return XCTFail("Expected noDiskSpace")
        }
    }

    // MARK: Private

    private let ampleCapacity = 10 * FileSystemError.lowAvailableCapacity
    private let lowCapacity = FileSystemError.lowAvailableCapacity - 1

    private func posixError(_ code: Int32) -> NSError {
        NSError(domain: NSPOSIXErrorDomain, code: Int(code))
    }
}
