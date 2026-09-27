//
//  AppMigrator.swift
//  Quran
//
//  Created by Mohamed Afifi on 9/10/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
//

import Foundation
import SystemDependencies
import VLogging

public protocol Migrator {
    var blocksUI: Bool { get }
    var uiTitle: String? { get }

    func execute(update: LaunchVersionUpdate) async
}

public enum MigrationStatus: Equatable {
    case noMigration
    case migrate(blocksUI: Bool, titles: Set<String>)
}

public final class AppMigrator {
    // MARK: Lifecycle

    public convenience init() {
        self.init(bundle: DefaultSystemBundle())
    }

    public init(bundle: SystemBundle) {
        updater = AppVersionUpdater(bundle: bundle)
    }

    // MARK: Public

    public var launchVersion: LaunchVersionUpdate { updater.launchVersion() }

    public func register(migrator: Migrator, for version: AppVersion) {
        migrators.append((version, migrator))
    }

    public func migrationStatus() -> MigrationStatus {
        let updaters = versionUpdaters()
        if updaters.isEmpty {
            updater.commitUpdates()
            return .noMigration
        } else {
            let blocksUI = updaters.contains { $0.blocksUI }
            let titles = Set(updaters.compactMap(\.uiTitle))
            return .migrate(blocksUI: blocksUI, titles: titles)
        }
    }

    public func migrate() async {
        let launchVersion = updater.launchVersion()
        logger.notice("Version Update: \(launchVersion)")

        await withTaskGroup(of: Void.self) { taskGroup in
            let updaters = versionUpdaters()
            for updater in updaters {
                taskGroup.addTask {
                    await updater.execute(update: launchVersion)
                }
            }
        }
        updater.commitUpdates()
    }

    // MARK: Private

    private var migrators: [(AppVersion, Migrator)] = []
    private let updater: AppVersionUpdater

    private func versionUpdaters() -> [Migrator] {
        switch launchVersion {
        case let .update(old, new):
            return updaters(from: old, to: new)
        case .firstLaunch, .sameVersion:
            // A new installation has nothing to migrate, and the same version already migrated.
            return []
        }
    }

    /// Returns updaters where: oldVersion < updater.version <= newVersion.
    private func updaters(from old: AppVersion, to new: AppVersion) -> [Migrator] {
        migrators
            .filter { version, _ in
                old.compare(version, options: .numeric) == .orderedAscending &&
                    version.compare(new, options: .numeric) != .orderedDescending
            }
            .map { $1 }
    }
}
