#if QURAN_SYNC
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
        AuthFlowFactoryProvider.shared.doInitialize()
        appGraph = SharedDependencyGraph.shared.doInit(
            driverFactory: DriverFactory(),
            storage: AppleMobileSyncStorageFactory.shared.create(),
            clientId: "",
            clientSecret: nil
        )
    }
}
#endif
