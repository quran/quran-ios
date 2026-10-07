//
//  PersistentStoreFailure.swift
//
//
//  Created by Mohamed Afifi on 2026-10-07.
//

import CoreData
import Foundation

/// Classifies errors from loading a persistent store.
public enum PersistentStoreFailure {
    // MARK: Public

    /// Free space, in bytes, below which a failure to open a store counts as storage full.
    ///
    /// A full device doesn't always fail with `SQLITE_FULL`. With nothing left, SQLite can't
    /// create the store's `-shm` file and reports `SQLITE_CANTOPEN` (14), or `SQLITE_IOERR`
    /// (10) partway through a write. Opening a store needs a few MB for its write-ahead log,
    /// and iOS warns that storage is almost full well before 50 MB, so an open that fails
    /// below this is far more likely the device than a damaged store. If space is freed and
    /// the failure persists, it's no longer classified as storage full and crashes as before.
    public static let lowAvailableCapacity = 50 * 1024 * 1024

    /// Whether `error`, or an error it wraps through `NSUnderlyingErrorKey`, reports
    /// that the device is out of storage.
    ///
    /// Opening a SQLite store writes its journal and metadata, so a full device fails the
    /// open itself, usually as a Cocoa error carrying `SQLITE_FULL`.
    public static func isStorageFull(_ error: any Error) -> Bool {
        errorChain(of: error).contains(where: reportsStorageFull)
    }

    /// Whether a store that failed to open with `error` should be treated as the device
    /// being out of storage.
    ///
    /// Besides errors that report a full device, any failure counts when the volume is
    /// nearly full, except a damaged store or an incompatible model, which free space can't fix.
    ///
    /// - Parameter availableCapacity: The free space, in bytes, of the volume holding the store,
    ///   from `URLResourceValues.volumeAvailableCapacity`, or `nil` if it couldn't be read.
    ///   Without it, only the error is considered.
    public static func isStorageFull(_ error: any Error, availableCapacity: Int?) -> Bool {
        let chain = errorChain(of: error)
        if chain.contains(where: reportsStorageFull) {
            return true
        }
        if chain.contains(where: reportsSpaceIndependentFailure) {
            return false
        }
        guard let availableCapacity else {
            return false
        }
        return availableCapacity < lowAvailableCapacity
    }

    // MARK: Private

    private static let sqliteErrorDomain = "NSSQLiteErrorDomain"
    private static let sqliteCorrupt = 11 // SQLITE_CORRUPT
    private static let sqliteFull = 13 // SQLITE_FULL
    private static let sqliteNotADatabase = 26 // SQLITE_NOTADB

    /// Core Data failures caused by the store's model or a migration, not by free space.
    private static let incompatibleStoreCodes: Set<Int> = [
        NSPersistentStoreIncompatibleSchemaError,
        NSPersistentStoreIncompatibleVersionHashError,
        NSMigrationError,
        NSMigrationMissingSourceModelError,
        NSMigrationMissingMappingModelError,
        NSInferredMappingModelError,
    ]

    /// Guards against an underlying error chain that refers back to itself.
    private static let maximumUnderlyingErrorDepth = 16

    /// `error` followed by the errors it wraps through `NSUnderlyingErrorKey`.
    private static func errorChain(of error: any Error) -> [NSError] {
        var chain: [NSError] = []
        var current: NSError? = error as NSError
        while let error = current, chain.count < maximumUnderlyingErrorDepth {
            chain.append(error)
            current = error.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return chain
    }

    private static func reportsStorageFull(_ error: NSError) -> Bool {
        if primarySQLiteCodes(of: error).contains(sqliteFull) {
            return true
        }
        switch error.domain {
        case NSCocoaErrorDomain:
            return error.code == NSFileWriteOutOfSpaceError
        case NSPOSIXErrorDomain:
            return error.code == Int(ENOSPC)
        default:
            return false
        }
    }

    private static func reportsSpaceIndependentFailure(_ error: NSError) -> Bool {
        let sqliteCodes = primarySQLiteCodes(of: error)
        if sqliteCodes.contains(sqliteCorrupt) || sqliteCodes.contains(sqliteNotADatabase) {
            return true
        }
        return error.domain == NSCocoaErrorDomain && incompatibleStoreCodes.contains(error.code)
    }

    /// The primary SQLite result codes `error` reports, dropping the extended code bits.
    ///
    /// Core Data reports SQLite failures as Cocoa errors with the SQLite code in `userInfo`.
    private static func primarySQLiteCodes(of error: NSError) -> [Int] {
        var codes: [Int] = []
        if error.domain == sqliteErrorDomain {
            codes.append(error.code)
        }
        if let code = error.userInfo[sqliteErrorDomain] as? Int {
            codes.append(code)
        }
        return codes.map { $0 & 0xFF }
    }
}
