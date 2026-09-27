//
//  TemporaryCoreDataStore.swift
//
//
//  Created by Mohamed Afifi on 2026-09-27.
//

import CoreData
import CoreDataModel
import CoreDataPersistence
import Foundation

/// A real SQLite store with a unique name, for tests that reopen, migrate, or corrupt a store.
public final class TemporaryCoreDataStore {
    // MARK: Lifecycle

    public init() {}

    deinit {
        removeStoreFiles()
        // History processing stores its token in a directory named after the store.
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(name, isDirectory: true))
    }

    // MARK: Public

    /// The first Quran model version, before page mushaf IDs existed.
    public static let firstModelURL = CoreDataModelResources.quranModel.appendingPathComponent("Quran.mom")

    public let name = "TemporaryCoreDataStore-\(UUID().uuidString)"

    public var storeURL: URL {
        directory.appendingPathComponent("\(name).sqlite")
    }

    /// Opens the store without uniquifiers. Pass ``firstModelURL`` to create a first-version store.
    public func stack(modelUrl: URL = CoreDataModelResources.quranModel) -> CoreDataStack {
        CoreDataStack(name: name, modelUrl: modelUrl, lazyUniquifiers: { [] })
    }

    /// Replaces the store with a file that SQLite cannot open.
    public func corrupt() throws {
        removeStoreFiles()
        try Data("not a database".utf8).write(to: storeURL)
    }

    /// Removes every store file, so the next open creates an empty store.
    public func removeStoreFiles() {
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(atPath: storeURL.path + suffix)
        }
    }

    // MARK: Private

    private let directory = NSPersistentContainer.defaultDirectoryURL()
}
