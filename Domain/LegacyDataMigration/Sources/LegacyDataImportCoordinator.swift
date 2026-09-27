#if QURAN_SYNC
//
//  LegacyDataImportCoordinator.swift
//
//
//  Created by Mohamed Afifi on 2026-09-27.
//

import Foundation
import LegacyDataPersistence
@preconcurrency import MobileSync
import Preferences
import VLogging

/// Imports the legacy Core Data store into MobileSync, once for the upgrade migration and again
/// whenever CloudKit changes the store.
///
/// Every scan reads the whole store and submits it as one tracked import, so MobileSync skips
/// content it already handled, even after the user edits or deletes it. Scans never overlap, and
/// requests made during a scan share one follow-up scan.
///
/// Use one instance for the whole app, so ``disable()`` waits for every scan.
public actor LegacyDataImportCoordinator {
    // MARK: Lifecycle

    public init(reader: CoreDataLegacyDataReader, quranDataService: QuranDataService) {
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
    private let quranDataService: QuranDataService
    private let preferences = LegacyImportPreferences.shared

    private var changesTask: Task<Void, Never>?
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
            let result = try await quranDataService.importData(data: data, deleteExisting: false, trackHistory: true)
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
            logger.error("Legacy import: failed in \(milliseconds(since: start))ms error=\(Self.category(of: error))")
            return .failure(error)
        }
    }

    /// The error's type, without its message, which may contain user content.
    private static func category(of error: Error) -> String {
        let error = error as NSError
        if let exception = error.userInfo["KotlinException"] {
            return String(describing: type(of: exception))
        }
        return "\(error.domain)#\(error.code)"
    }

    private func milliseconds(since start: Date) -> Int {
        Int(Date().timeIntervalSince(start) * 1000)
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
