import CoreData
import CoreDataModel
import CoreDataPersistence
import XCTest
@testable import AppStructureFeature
#if QURAN_SYNC
import MobileSync
#endif

final class LaunchStoresTests: XCTestCase {
    // MARK: Internal

    override func tearDownWithError() throws {
        for url in createdFiles {
            try? FileManager.default.removeItem(at: url)
        }
        try super.tearDownWithError()
    }

    // MARK: Opening

    @MainActor
    func testUnreadableCoreDataStoreFailsLaunch() async throws {
        let name = "LaunchStoresTests-\(UUID().uuidString)"
        try writeUnreadableStore(named: name)
        let sut = LaunchStores(coreDataStore: CoreDataStore(
            name: name,
            modelUrl: CoreDataModelResources.quranModel,
            lazyUniquifiers: { [] }
        ))

        guard case let .failure(.failed(message)) = await sut.open() else {
            return XCTFail("Expected launch to fail")
        }
        XCTAssertTrue(message.hasPrefix("###openStore(): Failed to load persistent store: "), message)
    }

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

    private var createdFiles: [URL] = []

    /// The shape Core Data reports when SQLite fails to open a store.
    private static func sqliteError(code: Int) -> NSError {
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
