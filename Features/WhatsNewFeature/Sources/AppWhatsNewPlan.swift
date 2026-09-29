//
//  AppWhatsNewPlan.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import AppMigrator
import Foundation

/// What What's New does after launch.
enum AppWhatsNewPlan {
    /// Nothing new since the last seen version.
    case none
    /// A fresh install starts with every version already seen.
    case markSeen(version: String)
    /// Present these unseen versions.
    case present([WhatsNewVersion])

    // MARK: Lifecycle

    /// - Parameters:
    ///   - lastSeenVersion: The last version the user saw. The `-whats-new.seen-version 0`
    ///     launch argument overrides it, so a fresh install with the argument still presents.
    ///   - launchVersion: How this launch relates to the previous one, captured before
    ///     the launch commits the current app version.
    init(whatsNew: AppWhatsNew, lastSeenVersion: String?, launchVersion: LaunchVersionUpdate) {
        if case .firstLaunch = launchVersion, lastSeenVersion == nil {
            self = whatsNew.versions.latestVersion.map { .markSeen(version: $0) } ?? .none
            return
        }

        let unseenVersions = whatsNew.versions.filter { version in
            guard let lastSeenVersion else {
                return true
            }
            return version.version.compare(lastSeenVersion, options: .numeric) == .orderedDescending
        }
        self = unseenVersions.isEmpty ? .none : .present(unseenVersions)
    }
}

extension [WhatsNewVersion] {
    var latestVersion: String? {
        map(\.version).max { lhs, rhs in
            lhs.compare(rhs, options: .numeric) == .orderedAscending
        }
    }
}
