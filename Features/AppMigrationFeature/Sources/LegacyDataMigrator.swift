#if QURAN_SYNC
//
//  LegacyDataMigrator.swift
//
//
//  Created by Mohamed Afifi on 2026-09-27.
//

import AppMigrator
import Foundation
import LegacyDataMigration
import Localization
import VLogging

/// Imports the legacy Core Data store into MobileSync before an upgraded app shows its UI.
///
/// It retries a failed import a few times and then lets the app launch. Later scans, on the next
/// launch or the next store change, import anything a failed attempt missed.
public struct LegacyDataMigrator: Migrator {
    // MARK: Lifecycle

    public init(coordinator: LegacyDataImportCoordinator, retryDelay: TimeInterval = 1) {
        self.coordinator = coordinator
        self.retryDelay = retryDelay
    }

    // MARK: Public

    public var blocksUI: Bool { true }
    public var uiTitle: String? { l("update.filesystem.title") }

    public func execute(update: LaunchVersionUpdate) async {
        for attempt in 1 ... Self.attempts {
            do {
                try await coordinator.importNow()
                logger.notice("Legacy migration: completed on attempt \(attempt)")
                return
            } catch {
                logger.error("Legacy migration: attempt \(attempt) failed")
            }
            if attempt < Self.attempts {
                try? await Task.sleep(nanoseconds: UInt64(retryDelay * Double(attempt) * 1_000_000_000))
            }
        }
        logger.error("Legacy migration: launching without it; later scans retry")
    }

    // MARK: Private

    private static let attempts = 3

    private let coordinator: LegacyDataImportCoordinator
    private let retryDelay: TimeInterval
}
#endif
