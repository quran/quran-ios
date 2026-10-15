#if QURAN_SYNC
import Foundation
import MobileSync
import XCTest

/// The real MobileSync database for tests, in a file only this process uses.
///
/// Test bundles and concurrent runs on one simulator share its database directory, so the file has a unique
/// name. It is closed and deleted when the test bundle finishes.
public final class MobileSyncTestDatabase: @unchecked Sendable {
    // MARK: Lifecycle

    private init() {
        AuthFlowFactoryProvider.shared.doInitialize()
        appGraph = SharedDependencyGraph.shared.doInit(
            driverFactory: DriverFactory(name: "quran-tests-\(UUID().uuidString).db"),
            storage: AppleMobileSyncStorageFactory.shared.create(),
            clientId: "",
            clientSecret: nil
        )
        DatabaseDeleter.register()
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
}

/// Deletes the database after the bundle's last test, once the graph's work stops and the database closes.
private final class DatabaseDeleter: NSObject, XCTestObservation {
    // MARK: Internal

    static func register() {
        if Thread.isMainThread {
            XCTestObservationCenter.shared.addTestObserver(DatabaseDeleter())
        } else {
            DispatchQueue.main.async {
                XCTestObservationCenter.shared.addTestObserver(DatabaseDeleter())
            }
        }
    }

    func testBundleDidFinish(_ testBundle: Bundle) {
        // Kotlin finishes stopping the graph's work on the main queue, so keep the run loop turning.
        let deleted = Deletion()
        Task { @MainActor in
            do {
                try await SharedDependencyGraph.shared.deleteDatabase()
            } catch {
                print("Failed to delete the MobileSync test database: \(error)")
            }
            deleted.isFinished = true
        }
        let deadline = Date().addingTimeInterval(10)
        while !deleted.isFinished, Date() < deadline {
            RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }
    }

    // MARK: Private

    private final class Deletion: @unchecked Sendable {
        var isFinished = false
    }
}
#endif
