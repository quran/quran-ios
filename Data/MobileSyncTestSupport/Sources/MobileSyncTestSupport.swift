#if QURAN_SYNC
import Foundation
import MobileSync

public final class MobileSyncTestDatabase: @unchecked Sendable {
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

    private init() {
        Self.removeDatabaseFiles()
        AuthFlowFactoryProvider.shared.doInitialize()
        appGraph = SharedDependencyGraph.shared.doInit(
            driverFactory: DriverFactory(),
            storage: AppleMobileSyncStorageFactory.shared.create(),
            clientId: "",
            clientSecret: nil
        )
    }

    private static func removeDatabaseFiles() {
        guard let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return
        }

        let databaseURL = applicationSupportDirectory
            .appendingPathComponent("databases", isDirectory: true)
            .appendingPathComponent("quran.db")
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(atPath: databaseURL.path + suffix)
        }
    }
}
#endif
