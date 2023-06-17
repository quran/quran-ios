//
//  UpdateHandler.swift
//  Quran
//
//  Created by Mohamed Afifi on 9/10/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation
import SystemDependencies
import VLogging

public protocol VersionUpdater {
    var blocksUI: Bool { get }
    var uiTitle: String? { get }

    func execute(update: LaunchVersionUpdate) async
}

public enum UpgradeStatus: Equatable {
    case noUpgrade
    case upgrade(blocksUI: Bool, titles: Set<String>)
}

public final class UpdateHandler {
    // MARK: Lifecycle

    public convenience init() {
        self.init(bundle: DefaultSystemBundle())
    }

    public init(bundle: SystemBundle) {
        updater = AppVersionUpdater(bundle: bundle)
    }

    // MARK: Public

    public var launchVersion: LaunchVersionUpdate { updater.launchVersion() }

    public func register(updater: VersionUpdater, for version: AppVersion) {
        updaters.append((version, updater))
    }

    public func shouldUpgrade() -> UpgradeStatus {
        let updaters = versionUpdaters()
        if updaters.isEmpty {
            return .noUpgrade
        } else {
            let blocksUI = updaters.contains { $0.blocksUI }
            let titles = Set(updaters.compactMap(\.uiTitle))
            return .upgrade(blocksUI: blocksUI, titles: titles)
        }
    }

    public func upgrade() async {
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
    }

    // MARK: Private

    private var updaters: [(AppVersion, VersionUpdater)] = []
    private let updater: AppVersionUpdater

    private func versionUpdaters() -> [VersionUpdater] {
        switch launchVersion {
        case .update(let old, _), .firstLaunch(version: let old), .sameVersion(version: let old):
            return updaters(for: old)
        }
    }

    private func updaters(for version: String) -> [VersionUpdater] {
        updaters // Returns updaters where: oldVersion < updaters.version.
            .filter { version.compare($0.0, options: .numeric) == .orderedAscending }
            .map { $1 }
    }
}
