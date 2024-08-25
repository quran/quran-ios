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
        case .update(let old, _), .firstLaunch(version: let old), .sameVersion(version: let old):
            return updaters(for: old)
        }
    }

    private func updaters(for version: String) -> [Migrator] {
        migrators // Returns updaters where: oldVersion < updaters.version.
            .filter { version.compare($0.0, options: .numeric) == .orderedAscending }
            .map { $1 }
    }
}
