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
    ///   - lastSeenBuild: The TestFlight build the user saw `lastSeenVersion` on, if any.
    ///   - launchVersion: How this launch relates to the previous one, captured before
    ///     the launch commits the current app version.
    ///   - testFlightBuild: The build this TestFlight launch runs, or `nil` outside TestFlight.
    ///     Each new TestFlight build presents the current version's sync reveal again, even when
    ///     an earlier build of it was seen.
    init(
        whatsNew: AppWhatsNew,
        lastSeenVersion: String?,
        lastSeenBuild: String? = nil,
        launchVersion: LaunchVersionUpdate,
        testFlightBuild: String? = nil
    ) {
        if case .firstLaunch = launchVersion, lastSeenVersion == nil {
            self = whatsNew.versions.latestVersion.map { .markSeen(version: $0) } ?? .none
            return
        }

        let unseenVersions = whatsNew.versions.filter { version in
            guard let lastSeenVersion else {
                return true
            }
            switch version.version.compare(lastSeenVersion, options: .numeric) {
            case .orderedDescending:
                return true
            case .orderedSame:
                // The sync reveal, seen on an earlier TestFlight build of the version this launch runs.
                guard let testFlightBuild, version.reveal == .sync else {
                    return false
                }
                return lastSeenBuild != testFlightBuild
                    && version.version.isSameVersion(as: launchVersion.currentVersion)
            case .orderedAscending:
                return false
            }
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

extension LaunchVersionUpdate {
    /// The marketing version this launch runs.
    var currentVersion: AppVersion {
        switch self {
        case .sameVersion(let version), .firstLaunch(let version), .update(from: _, to: let version):
            version
        }
    }
}

extension String {
    /// Whether two marketing versions are the same, ignoring trailing zeros: "3.1" is "3.1.0".
    func isSameVersion(as other: String) -> Bool {
        func components(_ version: String) -> [Int] {
            var components = version.split(separator: ".").map { Int($0) ?? 0 }
            while components.last == 0 {
                components.removeLast()
            }
            return components
        }
        return components(self) == components(other)
    }
}
