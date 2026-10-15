#if QURAN_SYNC
import Foundation
import MobileSync

/// The real MobileSync database for tests, in a file only this process uses.
///
/// Test bundles and concurrent runs on one simulator share its database directory, so the file has a unique
/// name and is removed when the process exits.
public final class MobileSyncTestDatabase: @unchecked Sendable {
    // MARK: Lifecycle

    private init() {
        atexit { MobileSyncTestDatabase.removeDatabaseFiles() }
        AuthFlowFactoryProvider.shared.doInitialize()
        appGraph = SharedDependencyGraph.shared.doInit(
            driverFactory: DriverFactory(name: Self.databaseName),
            storage: AppleMobileSyncStorageFactory.shared.create(),
            clientId: "",
            clientSecret: nil
        )
    }

    // MARK: Public

    public static let shared = MobileSyncTestDatabase()

    public let appGraph: AppGraph

    public var quranDataService: QuranDataService {
        appGraph.quranDataService
    }

    public var authService: SyncAuthService {
        appGraph.authService
    }

    public func reset() async throws {
        try await quranDataService.logout(clearLocalData: true)
    }

    // MARK: Private

    private static let databaseName = "quran-tests-\(UUID().uuidString).db"

    private static func removeDatabaseFiles() {
        guard let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return
        }

        let databaseURL = applicationSupportDirectory
            .appendingPathComponent("databases", isDirectory: true)
            .appendingPathComponent(databaseName)
        for suffix in ["", "-shm", "-wal", "-journal"] {
            try? FileManager.default.removeItem(atPath: databaseURL.path + suffix)
        }
    }
}
#endif
