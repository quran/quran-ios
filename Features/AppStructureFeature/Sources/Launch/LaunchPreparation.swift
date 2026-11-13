import AppDependencies
import AppMigrationFeature
import AppMigrator
import Crashing
import ReciterService
import UIKit
import VLogging

/// Opens and upgrades app data for both scene launches and background actions.
/// Keep one instance in the app container so simultaneous launches share migrations.
@MainActor
public final class LaunchPreparation {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
        stores = LaunchStores(coreDataStack: container.coreDataStack)
    }

    // MARK: Public

    /// Prepares data without creating a window or requiring a connected scene.
    /// A locked device fails promptly so a voice action can ask the user to unlock.
    public func prepare() async throws {
        guard UIApplication.shared.isProtectedDataAvailable else {
            throw LaunchPreparationError.protectedDataUnavailable
        }
        switch openStores() {
        case .success:
            await migrate()
            #if QURAN_SYNC
            await container.legacyDataImportCoordinator.start()
            #endif
        case let .failure(.storageFull(store, error)):
            crasher.recordError(
                StoreStorageFullError(store: store, underlying: error),
                reason: "Background launch couldn't open the \(store) store"
            )
            throw LaunchPreparationError.storageFull
        case let .failure(.failed(message)):
            logger.error("Background launch: \(message)")
            throw LaunchPreparationError.storeUnavailable
        }
    }

    // MARK: Internal

    var launchVersion: LaunchVersionUpdate { migrator.launchVersion }

    func openStores() -> Result<Void, LaunchStoreError> {
        stores.open()
    }

    func migrationStatus() -> MigrationStatus {
        if finishedMigration { return .noMigration }
        if let status { return status }
        registerMigrators()
        // Snapshot the previous version before migrationStatus commits it.
        _ = launchVersion
        let status = migrator.migrationStatus()
        self.status = status
        if status == .noMigration { finishedMigration = true }
        return status
    }

    func migrate() async {
        guard case .migrate = migrationStatus() else { return }
        if migrationTask == nil {
            let migrator = migrator
            migrationTask = Task { await migrator.migrate() }
        }
        await migrationTask?.value
        finishedMigration = true
    }

    // MARK: Private

    private let container: AppDependencies
    private let stores: LaunchStores
    private let migrator = AppMigrator()
    private var status: MigrationStatus?
    private var migrationTask: Task<Void, Never>?
    private var finishedMigration = false

    private func registerMigrators() {
        migrator.register(
            migrator: FileSystemMigrator(databasesURL: container.databasesURL, recitersRetreiver: ReciterDataRetriever()),
            for: "1.16.0"
        )
        migrator.register(migrator: RecitersPathMigrator(), for: "1.19.1")
        migrator.register(migrator: DownloadBackupMigrator(), for: "2.6.9")
        #if QURAN_SYNC
        migrator.register(migrator: LegacyDataMigrator(coordinator: container.legacyDataImportCoordinator), for: "3.1.0")
        #endif
    }
}

public enum LaunchPreparationError: LocalizedError {
    case protectedDataUnavailable
    case storageFull
    case storeUnavailable

    public var errorDescription: String? {
        switch self {
        case .protectedDataUnavailable:
            NSLocalizedString("Unlock your device to continue with Quran.", comment: "Siri cannot read protected app data")
        case .storageFull:
            NSLocalizedString("Free up space on your device, then try Quran again.", comment: "Siri cannot open the app database")
        case .storeUnavailable:
            NSLocalizedString("Open Quran to finish setting up your reading data, then try again.", comment: "Siri cannot prepare app data")
        }
    }
}
