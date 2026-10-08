//
//  LaunchStores.swift
//
//
//  Created by Mohamed Afifi on 2026-10-07.
//

import AppDependencies
import CoreData
import CoreDataPersistence
import Crashing
import Foundation
#if QURAN_SYNC
import MobileSync
#endif
import VLogging

/// Opens the stores the app reads at launch and creates the app's dependencies from them.
///
/// Opening them before building the app lets launch tell a device that's out of storage, which the
/// user can fix, from any other failure.
@MainActor
final class LaunchStores {
    // MARK: Lifecycle

    #if QURAN_SYNC
    init(
        host: AppHostDependencies,
        loadCoreDataStack: @escaping @Sendable () throws -> CoreDataStack = AppDependencies.loadCoreDataStack,
        openMobileSyncDatabase: @escaping () throws(MobileSyncDatabaseError) -> Void = {
            // The containers create the graph with `DriverFactory()` too, and the database is shared.
            try SharedDependencyGraph.shared.openDatabase(using: DriverFactory())
        }
    ) {
        self.host = host
        self.loadCoreDataStack = loadCoreDataStack
        self.openMobileSyncDatabase = openMobileSyncDatabase
    }
    #else
    init(
        host: AppHostDependencies,
        loadCoreDataStack: @escaping @Sendable () throws -> CoreDataStack = AppDependencies.loadCoreDataStack
    ) {
        self.host = host
        self.loadCoreDataStack = loadCoreDataStack
    }
    #endif

    // MARK: Internal

    /// Opens every store, stopping at the first one that fails. A failed open isn't kept, so
    /// calling again retries it. Once every store opens, later calls return the same dependencies.
    /// A call made while an open is in progress waits for that open.
    func open() async -> Result<AppDependencies, LaunchStoreError> {
        if let dependencies {
            return .success(dependencies)
        }
        if let openTask {
            return await openTask.value
        }
        let task = Task { await openStores() }
        openTask = task
        let result = await task.value
        openTask = nil
        return result
    }

    /// The free space on the volume holding `directory`, measured at its nearest existing
    /// ancestor, since the directory may not exist yet on a fresh install.
    ///
    /// Reads real free space rather than the "important usage" capacity, which counts space
    /// the system could purge but SQLite can't write to yet.
    nonisolated static func availableCapacity(at directory: URL) -> Int? {
        var existingDirectory = directory.standardizedFileURL
        while !FileManager.default.fileExists(atPath: existingDirectory.path), existingDirectory.pathComponents.count > 1 {
            existingDirectory = existingDirectory.deletingLastPathComponent()
        }
        do {
            let values = try existingDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            let capacity = values.volumeAvailableCapacity
            logger.notice("Launch stores: \(capacity.map(String.init) ?? "unknown") bytes available at \(existingDirectory.path)")
            return capacity
        } catch {
            logger.error("Launch stores: couldn't read the available capacity at \(existingDirectory.path). Error: \(error)")
            return nil
        }
    }

    // MARK: Private

    private let host: AppHostDependencies
    private let loadCoreDataStack: @Sendable () throws -> CoreDataStack
    #if QURAN_SYNC
    private let openMobileSyncDatabase: () throws(MobileSyncDatabaseError) -> Void
    #endif
    private var openedCoreDataStack: CoreDataStack?
    private var dependencies: AppDependencies?
    private var openTask: Task<Result<AppDependencies, LaunchStoreError>, Never>?

    private func openStores() async -> Result<AppDependencies, LaunchStoreError> {
        let coreDataStack: CoreDataStack
        if let openedCoreDataStack {
            coreDataStack = openedCoreDataStack
        } else {
            switch await Self.loadCoreDataStack(using: loadCoreDataStack) {
            case let .success(stack):
                coreDataStack = stack
            case let .failure(error):
                return .failure(error)
            }
            // Kept, so retrying a later store never opens this file with a second coordinator.
            openedCoreDataStack = coreDataStack
        }
        #if QURAN_SYNC
        do {
            try openMobileSyncDatabase()
        } catch {
            crashContext.setPersistence(store: "mobile_sync", operation: "open", phase: "failed")
            return .failure(LaunchStoreError(mobileSyncError: error, availableCapacity: Self.availableCapacity()))
        }
        // Clears a failure recorded by an earlier attempt.
        crashContext.setPersistence(store: "mobile_sync", operation: "open", phase: "ready")
        #endif
        let dependencies = AppDependencies(host: host, coreDataStack: coreDataStack)
        self.dependencies = dependencies
        return .success(dependencies)
    }

    /// Loads the store off the main thread. The first launch after a model change migrates the
    /// store inside the load, which can take seconds.
    @concurrent
    private nonisolated static func loadCoreDataStack(
        using load: @Sendable () throws -> CoreDataStack
    ) async -> Result<CoreDataStack, LaunchStoreError> {
        do {
            return .success(try load())
        } catch {
            return .failure(LaunchStoreError(coreDataError: error, availableCapacity: availableCapacity()))
        }
    }

    /// The free space on the volume holding the stores, which all live under Application Support.
    private nonisolated static func availableCapacity() -> Int? {
        availableCapacity(at: NSPersistentContainer.defaultDirectoryURL())
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
            // Keeps the message the app crashed with before launch opened the store, so crash
            // reports stay comparable.
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
                self = .failed(message: "###openDatabase(using:): Failed to open the MobileSync database: \(underlying)")
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
