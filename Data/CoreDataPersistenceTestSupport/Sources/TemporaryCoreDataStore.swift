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
import Utilities

/// A real SQLite store with a unique name, removed after this object and every coordinator that opened it are released.
///
/// Never share a store name between tests: Core Data keeps every store in one directory, which test
/// bundles and concurrent runs on the same simulator share.
///
/// Removal never runs if the test process exits first, so the first store in each process also
/// removes stores that earlier processes left behind.
public final class TemporaryCoreDataStore {
    // MARK: Lifecycle

    public init() {
        _ = Self.removedLeftoverStores
        storesObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreCoordinatorStoresDidChange,
            object: nil,
            queue: nil
        ) { [storeFileName = "\(name).sqlite", coordinators] notification in
            guard let coordinator = notification.object as? NSPersistentStoreCoordinator,
                  let stores = notification.userInfo?[NSAddedPersistentStoresKey] as? [NSPersistentStore],
                  stores.contains(where: { $0.url?.lastPathComponent == storeFileName })
            else {
                return
            }
            coordinators.withCriticalRegion { $0.append(WeakCoordinator(coordinator: coordinator)) }
        }
    }

    deinit {
        if let storesObserver {
            NotificationCenter.default.removeObserver(storesObserver)
        }
        // History processing stores its token in a directory named after the store.
        let urls = storeFileURLs + [directory.appendingPathComponent(name, isDirectory: true)]
        Self.removeWhenClosed(urls, coordinators: coordinators)
    }

    // MARK: Public

    /// The first Quran model version, before page mushaf IDs existed.
    public static let firstModelURL = CoreDataModelResources.quranModel.appendingPathComponent("Quran.mom")

    public let name = "\(TemporaryCoreDataStore.namePrefix)\(UUID().uuidString)"

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
        for url in storeFileURLs {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Removes every temporary store in `directory` whose files were all last modified before `date`.
    ///
    /// A store that a running process still uses keeps changing, so a store untouched since `date`
    /// was left behind by a process that exited before its cleanup ran.
    public static func removeStores(in directory: URL, modifiedBefore date: Date) {
        let fileManager = FileManager.default
        let urls = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        // Groups each store's SQLite files with the history directory named after it.
        let stores = Dictionary(grouping: urls.filter { $0.lastPathComponent.hasPrefix(namePrefix) }) { url in
            url.lastPathComponent.prefix { $0 != "." }
        }
        for storeURLs in stores.values where storeURLs.allSatisfy({ lastModified($0) < date }) {
            for url in storeURLs {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    // MARK: Private

    private struct WeakCoordinator {
        weak var coordinator: NSPersistentStoreCoordinator?
    }

    private static let namePrefix = "TemporaryCoreDataStore-"
    private static let defaultDirectory = NSPersistentContainer.defaultDirectoryURL()
    private static let leftoverStoreAge: TimeInterval = 60 * 60

    /// Removes leftovers once per process. An hour leaves alone every store a concurrent run still uses.
    private static let removedLeftoverStores: Void = removeStores(
        in: defaultDirectory,
        modifiedBefore: Date().addingTimeInterval(-leftoverStoreAge)
    )

    private let directory = TemporaryCoreDataStore.defaultDirectory
    private let coordinators = ManagedCriticalState<[WeakCoordinator]>([])
    private var storesObserver: NSObjectProtocol?

    private var storeFileURLs: [URL] {
        ["", "-shm", "-wal"].map { URL(fileURLWithPath: storeURL.path + $0) }
    }

    /// The latest modification date of `url` and, for a directory, of everything inside it.
    private static func lastModified(_ url: URL) -> Date {
        let key = URLResourceKey.contentModificationDateKey
        let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [key])
        let urls = [url] + (enumerator?.compactMap { $0 as? URL } ?? [])
        // A file removed meanwhile, or one whose date can't be read, counts as just modified.
        return urls.map { (try? $0.resourceValues(forKeys: [key]).contentModificationDate) ?? .distantFuture }.max() ?? .distantFuture
    }

    /// Removes `urls` once every coordinator that opened the store is released, which closes its connections.
    ///
    /// Work queued after a save, such as history processing and WAL checkpoints, keeps a coordinator
    /// alive after its stack is released, often until the test's autorelease pool drains. Removing the
    /// files under that work fails it with a SQLite disk I/O error, so removal waits in the background.
    private static func removeWhenClosed(_ urls: [URL], coordinators: ManagedCriticalState<[WeakCoordinator]>) {
        DispatchQueue.global(qos: .utility).async {
            let deadline = Date().addingTimeInterval(30)
            while coordinators.withCriticalRegion({ $0.contains { $0.coordinator != nil } }), Date() < deadline {
                Thread.sleep(forTimeInterval: 0.05)
            }
            for url in urls {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
