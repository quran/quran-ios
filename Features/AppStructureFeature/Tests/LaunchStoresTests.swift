import Analytics
import AppDependencies
import BatchDownloader
import CoreData
import CoreDataModel
import CoreDataPersistence
import CoreDataPersistenceTestSupport
import NoorUI
import ReadingService
import Utilities
import XCTest
@testable import AppStructureFeature
#if QURAN_SYNC
import AuthenticationClient
import MobileSync
#endif

@MainActor
final class LaunchStoresTests: XCTestCase {
    // MARK: Internal

    override func tearDownWithError() throws {
        for url in createdFiles {
            try? FileManager.default.removeItem(at: url)
        }
        try super.tearDownWithError()
    }

    // MARK: Opening

    func testUnreadableCoreDataStoreFailsLaunch() async throws {
        let name = "LaunchStoresTests-\(UUID().uuidString)"
        try writeUnreadableStore(named: name)
        let sut = makeSUT(loadCoreDataStack: {
            try CoreDataStack(name: name, modelUrl: CoreDataModelResources.quranModel, lazyUniquifiers: { [] })
        })

        guard case let .failure(.failed(message)) = await sut.open() else {
            return XCTFail("Expected launch to fail")
        }
        XCTAssertTrue(message.hasPrefix("###openStore(): Failed to load persistent store: "), message)
    }

    func testCoreDataStoreLoadsOffTheMainThread() async throws {
        let store = store
        let loadedOnMainThread = ManagedCriticalState<Bool?>(nil)
        let sut = makeSUT(loadCoreDataStack: {
            loadedOnMainThread.withCriticalRegion { $0 = Thread.isMainThread }
            return try store.stack()
        })

        _ = try await sut.open().get()

        XCTAssertEqual(loadedOnMainThread.withCriticalRegion { $0 }, false)
    }

    func testOpeningAgainReusesTheOpenStores() async throws {
        let store = store
        let loads = ManagedCriticalState(0)
        let sut = makeSUT(loadCoreDataStack: {
            loads.withCriticalRegion { $0 += 1 }
            return try store.stack()
        })

        let first = try await sut.open().get()
        let second = try await sut.open().get()

        XCTAssertIdentical(first, second)
        XCTAssertEqual(loads.withCriticalRegion { $0 }, 1)
    }

    func testOpenInProgressIsShared() async throws {
        let store = store
        let loads = ManagedCriticalState(0)
        let loading = expectation(description: "The store starts loading")
        let finishLoading = DispatchSemaphore(value: 0)
        let sut = makeSUT(loadCoreDataStack: {
            loads.withCriticalRegion { $0 += 1 }
            loading.fulfill()
            finishLoading.wait()
            return try store.stack()
        })

        async let first = sut.open()
        await fulfillment(of: [loading], timeout: 5)
        async let second = sut.open()
        // Frees the main actor, so the second open joins the first while its load is blocked.
        try await Task.sleep(nanoseconds: 100_000_000)
        finishLoading.signal()
        let results = await [first, second]

        XCTAssertIdentical(try results[0].get(), try results[1].get())
        XCTAssertEqual(loads.withCriticalRegion { $0 }, 1)
    }

    func testFailedCoreDataOpenIsRetried() async throws {
        let store = store
        let isStorageFull = ManagedCriticalState(true)
        let sut = makeSUT(loadCoreDataStack: {
            if isStorageFull.withCriticalRegion({ $0 }) {
                throw Self.sqliteError(code: 13)
            }
            return try store.stack()
        })
        guard case .failure(.storageFull) = await sut.open() else {
            return XCTFail("Expected the store to be full")
        }

        isStorageFull.withCriticalRegion { $0 = false }

        _ = try await sut.open().get()
    }

    #if QURAN_SYNC
    func testRetryAfterMobileSyncFailsKeepsTheOpenCoreDataStore() async throws {
        let store = store
        let loads = ManagedCriticalState(0)
        var isStorageFull = true
        let sut = LaunchStores(
            host: UnusedHostDependencies(),
            loadCoreDataStack: {
                loads.withCriticalRegion { $0 += 1 }
                return try store.stack()
            },
            openMobileSyncDatabase: { () throws(MobileSyncDatabaseError) in
                if isStorageFull {
                    throw .storageFull(underlying: Self.sqliteError(code: 13))
                }
            }
        )
        guard case .failure(.storageFull) = await sut.open() else {
            return XCTFail("Expected the database to be full")
        }

        isStorageFull = false

        _ = try await sut.open().get()
        XCTAssertEqual(loads.withCriticalRegion { $0 }, 1)
    }
    #endif

    // MARK: Available capacity

    func testAvailableCapacityOfAMissingDirectoryIsMeasuredAtItsNearestAncestor() {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("LaunchStoresTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)

        XCTAssertNotNil(LaunchStores.availableCapacity(at: missing))
    }

    // MARK: Core Data errors

    func testCoreDataStorageFullIsStorageFull() {
        let sut = LaunchStoreError(coreDataError: Self.sqliteError(code: 13), availableCapacity: Self.plentyOfCapacity)

        XCTAssertEqual(sut.storageFullStore, "core_data")
    }

    func testCoreDataCantOpenOnALowVolumeIsStorageFull() {
        let sut = LaunchStoreError(coreDataError: Self.sqliteError(code: 14), availableCapacity: Self.lowCapacity)

        XCTAssertEqual(sut.storageFullStore, "core_data")
    }

    func testCoreDataCantOpenWithPlentyOfSpaceCrashesWithTheStoreError() {
        let error = Self.sqliteError(code: 14)

        let sut = LaunchStoreError(coreDataError: error, availableCapacity: Self.plentyOfCapacity)

        XCTAssertEqual(sut.failureMessage, "###openStore(): Failed to load persistent store: \(error)")
    }

    func testCoreDataStorageFullWithoutCapacityIsStorageFull() {
        let sut = LaunchStoreError(coreDataError: Self.sqliteError(code: 13), availableCapacity: nil)

        XCTAssertEqual(sut.storageFullStore, "core_data")
    }

    func testCoreDataCantOpenWithoutCapacityCrashes() {
        let sut = LaunchStoreError(coreDataError: Self.sqliteError(code: 14), availableCapacity: nil)

        XCTAssertNotNil(sut.failureMessage)
    }

    // MARK: MobileSync errors

    #if QURAN_SYNC
    func testMobileSyncStorageFullIsStorageFull() {
        let error = MobileSyncDatabaseError.storageFull(underlying: Self.sqliteError(code: 13))

        let sut = LaunchStoreError(mobileSyncError: error, availableCapacity: Self.plentyOfCapacity)

        XCTAssertEqual(sut.storageFullStore, "mobile_sync")
    }

    func testMobileSyncCantOpenOnALowVolumeIsStorageFull() {
        let error = MobileSyncDatabaseError.openFailed(underlying: Self.sqliteError(code: 14))

        let sut = LaunchStoreError(mobileSyncError: error, availableCapacity: Self.lowCapacity)

        XCTAssertEqual(sut.storageFullStore, "mobile_sync")
    }

    func testMobileSyncFailedRollbackOnALowVolumeIsStorageFull() {
        // SQLiter can hide SQLITE_FULL behind a failed rollback.
        let error = MobileSyncDatabaseError.openFailed(underlying: NSError(domain: "KotlinException", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "cannot rollback - no transaction is active",
        ]))

        let sut = LaunchStoreError(mobileSyncError: error, availableCapacity: Self.lowCapacity)

        XCTAssertEqual(sut.storageFullStore, "mobile_sync")
    }

    func testMobileSyncOpenFailureWithPlentyOfSpaceCrashesWithTheUnderlyingError() {
        let underlying = Self.sqliteError(code: 14)
        let error = MobileSyncDatabaseError.openFailed(underlying: underlying)

        let sut = LaunchStoreError(mobileSyncError: error, availableCapacity: Self.plentyOfCapacity)

        XCTAssertEqual(sut.failureMessage, "###openDatabase(using:): Failed to open the MobileSync database: \(underlying)")
    }
    #endif

    // MARK: Reporting

    func testStorageFullReportHasItsOwnDomain() {
        let error = StoreStorageFullError(store: "core_data", underlying: Self.sqliteError(code: 13)) as NSError

        XCTAssertEqual(error.domain, "QuranEngine.StoreStorageFull")
    }

    func testStorageFullReportCarriesTheStoreError() {
        let underlying = Self.sqliteError(code: 13)

        let error = StoreStorageFullError(store: "core_data", underlying: underlying) as NSError

        XCTAssertEqual(error.userInfo[NSUnderlyingErrorKey] as? NSError, underlying)
    }

    // MARK: Private

    private static let lowCapacity = PersistentStoreFailure.lowAvailableCapacity - 1
    private static let plentyOfCapacity = 10 * PersistentStoreFailure.lowAvailableCapacity

    private let store = TemporaryCoreDataStore()
    private var createdFiles: [URL] = []

    /// Opens MobileSync without touching a database, so only the Core Data store is real.
    private func makeSUT(loadCoreDataStack: @escaping @Sendable () throws -> CoreDataStack) -> LaunchStores {
        #if QURAN_SYNC
        LaunchStores(host: UnusedHostDependencies(), loadCoreDataStack: loadCoreDataStack, openMobileSyncDatabase: {})
        #else
        LaunchStores(host: UnusedHostDependencies(), loadCoreDataStack: loadCoreDataStack)
        #endif
    }

    /// The shape Core Data reports when SQLite fails to open a store.
    private nonisolated static func sqliteError(code: Int) -> NSError {
        NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError, userInfo: [
            NSFilePathErrorKey: "/var/mobile/Containers/Data/Application/Library/Application Support/Quran.sqlite",
            "NSSQLiteErrorDomain": code,
        ])
    }

    /// Writes a file that isn't a SQLite database where `CoreDataStack` keeps the store `name`.
    private func writeUnreadableStore(named name: String) throws {
        let directory = NSPersistentContainer.defaultDirectoryURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = directory.appendingPathComponent("\(name).sqlite")
        createdFiles += ["", "-shm", "-wal"].map { URL(fileURLWithPath: store.path + $0) }
        try Data(repeating: 0x2A, count: 4096).write(to: store)
    }
}

/// Opening the stores never reads the host dependencies.
private struct UnusedHostDependencies: AppHostDependencies {
    var databasesURL: URL { fatalError("Unused in tests") }
    var wordsDatabase: URL { fatalError("Unused in tests") }
    var appHost: URL { fatalError("Unused in tests") }
    var filesAppHost: URL { fatalError("Unused in tests") }
    var quranProfileURL: URL { fatalError("Unused in tests") }
    var logsDirectory: URL { fatalError("Unused in tests") }
    var databasesDirectory: URL { fatalError("Unused in tests") }
    var supportsCloudKit: Bool { fatalError("Unused in tests") }
    var downloadManager: DownloadManager { fatalError("Unused in tests") }
    var analytics: AnalyticsLibrary { fatalError("Unused in tests") }
    var readingResources: ReadingResourcesService { fatalError("Unused in tests") }
    var remoteResources: ReadingRemoteResources? { fatalError("Unused in tests") }
    var appIconCatalog: AppIconCatalog { fatalError("Unused in tests") }
    #if QURAN_SYNC
    var authenticationClient: any AuthenticationClient { fatalError("Unused in tests") }
    var quranDataService: QuranDataService { fatalError("Unused in tests") }
    #endif
}

private extension LaunchStoreError {
    var storageFullStore: String? {
        guard case let .storageFull(store, _) = self else { return nil }
        return store
    }

    var failureMessage: String? {
        guard case let .failed(message) = self else { return nil }
        return message
    }
}
