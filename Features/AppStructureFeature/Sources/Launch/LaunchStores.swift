//
//  LaunchStores.swift
//
//
//  Created by Mohamed Afifi on 2026-10-07.
//

import CoreData
import CoreDataPersistence
import Crashing
import Foundation
#if QURAN_SYNC
import MobileSync
#endif
import Utilities
import VLogging

/// Opens the stores the app reads at launch, before anything resolves them.
///
/// Building the app reads them right away, and a read that can't open its store crashes. Opening
/// them first lets launch tell a device that's out of storage, which the user can fix, from any
/// other failure.
struct LaunchStores {
    // MARK: Internal

    let coreDataStack: CoreDataStack

    /// Opens every store, stopping at the first one that fails. A failed open isn't cached, so
    /// calling again retries it.
    func open() -> Result<Void, LaunchStoreError> {
        do {
            try coreDataStack.openStore()
        } catch {
            return .failure(LaunchStoreError(coreDataError: error, availableCapacity: Self.availableCapacity()))
        }
        #if QURAN_SYNC
        do {
            try MobileSyncGraph.openDatabase()
        } catch {
            crashContext.setPersistence(store: "mobile_sync", operation: "open", phase: "failed")
            return .failure(LaunchStoreError(mobileSyncError: error, availableCapacity: Self.availableCapacity()))
        }
        // Clears a failure recorded by an earlier attempt.
        crashContext.setPersistence(store: "mobile_sync", operation: "open", phase: "ready")
        #endif
        return .success(())
    }

    // MARK: Private

    /// The free space on the volume holding the stores, which all live under Application Support.
    /// The directory may not exist yet on a fresh install.
    private static func availableCapacity() -> Int? {
        let directory = NSPersistentContainer.defaultDirectoryURL()
        let capacity = FileManager.default.availableCapacity(at: directory)
        logger.notice("Launch stores: \(capacity.map(String.init) ?? "unknown") bytes available at \(directory.path)")
        return capacity
    }
}

/// Why launch couldn't open a store.
enum LaunchStoreError: Error {
    /// The device is out of storage. Freeing space and opening again can recover.
    case storageFull(store: String, underlying: any Error)
    /// Any other failure. Launch can't continue.
    case failed(message: String)

    // MARK: Lifecycle

    /// - Parameter availableCapacity: The free space on the store's volume, if it could be read.
    init(coreDataError error: any Error, availableCapacity: Int?) {
        if PersistentStoreFailure.isStorageFull(error, availableCapacity: availableCapacity) {
            self = .storageFull(store: "core_data", underlying: error)
        } else {
            // Matches the message `CoreDataStack` crashed with before launch opened the store,
            // so crash reports stay comparable.
            self = .failed(message: "###openStore(): Failed to load persistent store: \(error)")
        }
    }

    #if QURAN_SYNC
    /// - Parameter availableCapacity: The free space on the database's volume, if it could be read.
    init(mobileSyncError error: MobileSyncDatabaseError, availableCapacity: Int?) {
        switch error {
        case let .storageFull(underlying):
            self = .storageFull(store: "mobile_sync", underlying: underlying)
        case let .openFailed(underlying):
            // A full disk can also fail as SQLITE_CANTOPEN, or as a failed rollback that hides SQLITE_FULL.
            if PersistentStoreFailure.isStorageFull(underlying, availableCapacity: availableCapacity) {
                self = .storageFull(store: "mobile_sync", underlying: underlying)
            } else {
                self = .failed(message: "###MobileSyncGraph.openDatabase(): Failed to open the MobileSync database: \(underlying)")
            }
        }
    }
    #endif
}

/// Reported once per launch when a store can't open because the device is out of storage.
///
/// Its own error domain gives it its own Crashlytics issue, instead of grouping it with every
/// Cocoa or Kotlin error with the same code that a store can fail with.
struct StoreStorageFullError: CustomNSError {
    static let errorDomain = "QuranEngine.StoreStorageFull"

    let store: String
    let underlying: any Error

    var errorUserInfo: [String: Any] {
        [
            "store": store,
            NSUnderlyingErrorKey: underlying as NSError,
        ]
    }
}
