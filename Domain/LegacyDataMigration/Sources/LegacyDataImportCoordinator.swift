#if QURAN_SYNC
//
//  LegacyDataImportCoordinator.swift
//
//
//  Created by Mohamed Afifi on 2026-09-27.
//

import Crashing
import Foundation
import LegacyDataPersistence
import MobileSync
import Preferences
import VLogging

/// Imports the legacy Core Data store into MobileSync, once for the upgrade migration and again
/// whenever CloudKit changes the store.
///
/// Every scan reads the whole store and submits it as one tracked import, so MobileSync skips
/// content it already handled, even after the user edits or deletes it. Scans never overlap, and
/// requests made during a scan share one follow-up scan. A failed scan is retried by later scans,
/// and the first failure of each instance is reported to crash reporting by category only.
///
/// Use one instance for the whole app, so ``disable()`` waits for every scan.
public actor LegacyDataImportCoordinator {
    // MARK: Lifecycle

    public init(reader: CoreDataLegacyDataReader, quranDataService: MobileSyncDataService) {
        self.reader = reader
        self.quranDataService = quranDataService
    }

    deinit {
        changesTask?.cancel()
    }

    // MARK: Public

    /// Scans now and after every legacy store change. Later calls, and calls after ``disable()``, do nothing.
    public func start() async {
        guard changesTask == nil, preferences.isEnabled else {
            return
        }
        // Subscribe before the first scan so no change is missed.
        let changes = reader.changes()
        let runner = runner
        changesTask = Task {
            for await _ in changes {
                await runner.requestScan()
            }
        }
        await runner.requestScan()
    }

    /// Imports the whole legacy store, joining a scan that is already running or queued.
    ///
    /// Returns without importing when legacy import is disabled, and throws when the store cannot be
    /// read or the import fails.
    public func importNow() async throws {
        try await runner.scanNow()
    }

    /// Stops legacy import permanently and waits for a scan in progress. Call it before logout, so
    /// no import writes after the logout reset.
    public func disable() async {
        preferences.isEnabled = false
        changesTask?.cancel()
        await runner.waitForScans()
    }

    // MARK: Private

    private let reader: CoreDataLegacyDataReader
    private let quranDataService: MobileSyncDataService
    private let preferences = LegacyImportPreferences.shared

    private var changesTask: Task<Void, Never>?
    private var reportedFailure = false
    private lazy var runner = LegacyImportScanRunner { [weak self] in
        await self?.scan() ?? .success(())
    }

    private func scan() async -> Result<Void, Error> {
        guard preferences.isEnabled else {
            logger.info("Legacy import: disabled")
            return .success(())
        }
        let start = Date()
        do {
            let data = try await reader.importData()
            // Logout may disable import while the store is read.
            guard preferences.isEnabled else {
                logger.info("Legacy import: disabled during the scan")
                return .success(())
            }
            let result = try await quranDataService.importData(data, deleteExisting: false, trackHistory: true)
            logger.notice("""
            Legacy import: completed in \(milliseconds(since: start))ms changed=\(result.changed) \
            matched=\(result.matched) keptExisting=\(result.keptExisting) alreadyProcessed=\(result.alreadyProcessed)
            """)
            return .success(())
        } catch {
            // A reset after logout can interrupt the import; import is off then, so it is not a failure.
            guard preferences.isEnabled else {
                return .success(())
            }
            let category = Self.category(of: error)
            logger.error("Legacy import: failed in \(milliseconds(since: start))ms error=\(category)")
            if !(error is CancellationError) {
                reportFirstFailure(category: category)
            }
            return .failure(error)
        }
    }

    /// Reports only the first failure, so retries in the same launch add no duplicate reports.
    private func reportFirstFailure(category: String) {
        guard !reportedFailure else {
            return
        }
        reportedFailure = true
        crasher.recordError(LegacyImportFailure(category: category), reason: "Legacy import failed")
    }

    /// The error's type, without its message, which may contain user content.
    private static func category(of error: Error) -> String {
        if let error = error as? MobileSyncDataError {
            return error.category
        }
        let error = error as NSError
        return "\(error.domain)#\(error.code)"
    }

    private func milliseconds(since start: Date) -> Int {
        Int(Date().timeIntervalSince(start) * 1000)
    }
}

/// A failed scan reported without its underlying error, whose message may contain user content.
struct LegacyImportFailure: CustomNSError {
    static let errorDomain = "LegacyDataMigration.LegacyImportFailure"

    let category: String

    /// One code for every failure, so they group as one issue.
    var errorCode: Int {
        1
    }

    var errorUserInfo: [String: Any] {
        ["legacy_import_error": category]
    }
}

/// Whether legacy data may still be imported. It stays enabled after the upgrade migration so late
/// CloudKit arrivals import, and logout disables it permanently.
struct LegacyImportPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = LegacyImportPreferences()

    @Preference(enabled)
    var isEnabled: Bool

    static func reset() {
        Preferences.shared.removeValueForKey(enabled)
    }

    // MARK: Private

    private static let enabled = PreferenceKey<Bool>(key: "com.quran.legacy-import.enabled", defaultValue: true)
}
#endif
