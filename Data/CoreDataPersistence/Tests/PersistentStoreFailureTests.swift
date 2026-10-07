//
//  PersistentStoreFailureTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-07.
//

import CoreData
import CoreDataPersistence
import Foundation
import XCTest

final class PersistentStoreFailureTests: XCTestCase {
    // MARK: Storage full

    func test_cocoaErrorCarryingSQLiteFull_isStorageFull() {
        // The error Core Data reported when a full device couldn't open Quran.sqlite.
        XCTAssertTrue(PersistentStoreFailure.isStorageFull(storeError(sqliteCode: 13)))
    }

    func test_sqliteFull_isStorageFull() {
        XCTAssertTrue(PersistentStoreFailure.isStorageFull(NSError(domain: "NSSQLiteErrorDomain", code: 13)))
    }

    func test_extendedSQLiteFull_isStorageFull() {
        // An extended result code keeps the primary code in its low byte.
        XCTAssertTrue(PersistentStoreFailure.isStorageFull(storeError(sqliteCode: 13 | (1 << 8))))
    }

    func test_fileWriteOutOfSpace_isStorageFull() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteOutOfSpaceError)

        XCTAssertTrue(PersistentStoreFailure.isStorageFull(error))
    }

    func test_noSpaceLeftOnDevice_isStorageFull() {
        XCTAssertTrue(PersistentStoreFailure.isStorageFull(NSError(domain: NSPOSIXErrorDomain, code: Int(ENOSPC))))
    }

    func test_storageFullUnderlyingError_isStorageFull() {
        let sqliteFull = NSError(domain: "NSSQLiteErrorDomain", code: 13)
        let wrapped = NSError(domain: NSCocoaErrorDomain, code: NSPersistentStoreOpenError, userInfo: [
            NSUnderlyingErrorKey: NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError, userInfo: [
                NSUnderlyingErrorKey: sqliteFull,
            ]),
        ])

        XCTAssertTrue(PersistentStoreFailure.isStorageFull(wrapped))
    }

    func test_outOfSpaceUnderlyingError_isStorageFull() {
        let wrapped = NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError, userInfo: [
            NSUnderlyingErrorKey: NSError(domain: NSCocoaErrorDomain, code: NSFileWriteOutOfSpaceError),
        ])

        XCTAssertTrue(PersistentStoreFailure.isStorageFull(wrapped))
    }

    // MARK: Other failures

    func test_sqliteMisuse_isNotStorageFull() {
        XCTAssertFalse(PersistentStoreFailure.isStorageFull(NSError(domain: "NSSQLiteErrorDomain", code: 21)))
    }

    func test_cocoaErrorCarryingSQLiteMisuse_isNotStorageFull() {
        XCTAssertFalse(PersistentStoreFailure.isStorageFull(storeError(sqliteCode: 21)))
    }

    func test_noPermission_isNotStorageFull() {
        // Opening a protected store while the device is locked.
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError)

        XCTAssertFalse(PersistentStoreFailure.isStorageFull(error))
    }

    func test_sqliteAuth_isNotStorageFull() {
        XCTAssertFalse(PersistentStoreFailure.isStorageFull(storeError(sqliteCode: 23)))
    }

    func test_unrelatedCocoaError_isNotStorageFull() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSPersistentStoreIncompatibleVersionHashError, userInfo: [
            NSUnderlyingErrorKey: NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError),
        ])

        XCTAssertFalse(PersistentStoreFailure.isStorageFull(error))
    }

    func test_sqliteFullCodeInAnotherDomain_isNotStorageFull() {
        XCTAssertFalse(PersistentStoreFailure.isStorageFull(NSError(domain: NSURLErrorDomain, code: 13)))
    }

    func test_outOfSpaceCodeInAnotherDomain_isNotStorageFull() {
        let error = NSError(domain: NSOSStatusErrorDomain, code: NSFileWriteOutOfSpaceError)

        XCTAssertFalse(PersistentStoreFailure.isStorageFull(error))
    }

    func test_selfReferencingUnderlyingError_isNotStorageFull() {
        let error = SelfReferencingError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError)

        XCTAssertFalse(PersistentStoreFailure.isStorageFull(error))
    }

    // MARK: Available capacity

    func test_cantOpenWithLowCapacity_isStorageFull() {
        let capacity = PersistentStoreFailure.lowAvailableCapacity - 1

        XCTAssertTrue(PersistentStoreFailure.isStorageFull(cantOpenError, availableCapacity: capacity))
    }

    func test_cantOpenWithPlentyOfCapacity_isNotStorageFull() {
        let capacity = PersistentStoreFailure.lowAvailableCapacity

        XCTAssertFalse(PersistentStoreFailure.isStorageFull(cantOpenError, availableCapacity: capacity))
    }

    func test_cantOpenWithUnavailableCapacity_isNotStorageFull() {
        XCTAssertFalse(PersistentStoreFailure.isStorageFull(cantOpenError, availableCapacity: nil))
    }

    func test_sqliteFullWithUnavailableCapacity_isStorageFull() {
        XCTAssertTrue(PersistentStoreFailure.isStorageFull(storeError(sqliteCode: 13), availableCapacity: nil))
    }

    func test_storageFullErrorWithPlentyOfCapacity_isStorageFull() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteOutOfSpaceError)

        XCTAssertTrue(PersistentStoreFailure.isStorageFull(error, availableCapacity: plentyOfCapacity))
    }

    // MARK: Failures free space can't fix

    func test_corruptStoreWithLowCapacity_isNotStorageFull() {
        XCTAssertFalse(PersistentStoreFailure.isStorageFull(storeError(sqliteCode: 11), availableCapacity: lowCapacity))
    }

    func test_notADatabaseWithLowCapacity_isNotStorageFull() {
        XCTAssertFalse(PersistentStoreFailure.isStorageFull(storeError(sqliteCode: 26), availableCapacity: lowCapacity))
    }

    func test_incompatibleModelWithLowCapacity_isNotStorageFull() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSPersistentStoreIncompatibleVersionHashError)

        XCTAssertFalse(PersistentStoreFailure.isStorageFull(error, availableCapacity: lowCapacity))
    }

    func test_failedMigrationWithLowCapacity_isNotStorageFull() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSMigrationMissingMappingModelError)

        XCTAssertFalse(PersistentStoreFailure.isStorageFull(error, availableCapacity: lowCapacity))
    }

    func test_migrationFailingWithSQLiteFull_isStorageFull() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSMigrationError, userInfo: [
            NSUnderlyingErrorKey: storeError(sqliteCode: 13),
        ])

        XCTAssertTrue(PersistentStoreFailure.isStorageFull(error, availableCapacity: plentyOfCapacity))
    }

    // MARK: Private

    private let lowCapacity = PersistentStoreFailure.lowAvailableCapacity - 1
    private let plentyOfCapacity = 10 * PersistentStoreFailure.lowAvailableCapacity

    /// The error Core Data reported when a full device couldn't create the store's `-shm` file.
    private var cantOpenError: NSError {
        storeError(sqliteCode: 14) // SQLITE_CANTOPEN
    }

    /// The shape Core Data reports when SQLite fails to open a store.
    private func storeError(sqliteCode: Int) -> NSError {
        NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError, userInfo: [
            NSFilePathErrorKey: "/var/mobile/Containers/Data/Application/Library/Application Support/Quran.sqlite",
            "NSSQLiteErrorDomain": sqliteCode,
        ])
    }
}

/// An error that wraps itself, which `NSError` can't express through its initializer.
private final class SelfReferencingError: NSError {
    override var userInfo: [String: Any] {
        [NSUnderlyingErrorKey: self]
    }
}
