#if QURAN_SYNC
//
//  SyncRunRow.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import Foundation
import Localization
import MobileSync

/// A sync run, as the sync logs show it.
struct SyncRunRow: Identifiable, Equatable {
    enum Outcome: Equatable {
        case succeeded
        /// It ran but left something undone: it couldn't send the changes, or it was stopped.
        case partial
        case failed
    }

    // MARK: Lifecycle

    init(_ run: MobileSyncRun, formatter: DateFormatter = Self.dateFormatter) {
        id = run.startedAt
        title = lFormat("sync.run.title", formatter.string(from: run.endedAt), run.trigger.localizedName)
        detail = Self.detail(of: run)
        outcome = Self.outcome(of: run.result)
    }

    // MARK: Internal

    /// Today, 10:42, or Yesterday, 22:18, with the app's digits.
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .fixedCurrentLocaleNumbers
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    let id: Date
    let title: String
    let detail: String
    let outcome: Outcome

    // MARK: Private

    private static func detail(of run: MobileSyncRun) -> String {
        var parts: [String] = []
        switch run.result {
        case .failed:
            parts.append(run.error?.kind.localizedDescription ?? MobileSyncRunError.Kind.unknown.localizedDescription)
            if run.attempts > 1 {
                parts.append(lFormat("sync.run.attempts", run.attempts))
            }
            return parts.joined(separator: l("sync.separator"))
        case .succeeded, .pulledOnly, .cancelled:
            break
        }
        if run.pushed > 0 {
            parts.append(lFormat("sync.run.sent", NumberFormatter.shared.format(run.pushed)))
        }
        if run.pulled > 0 {
            parts.append(lFormat("sync.run.received", NumberFormatter.shared.format(run.pulled)))
        }
        if run.held > 0 {
            parts.append(lFormat("sync.run.held", NumberFormatter.shared.format(run.held)))
        }
        switch run.result {
        case .pulledOnly:
            parts.append(l("sync.run.sending-paused"))
        case .cancelled:
            parts.append(l("sync.run.stopped"))
        case .succeeded where parts.isEmpty:
            parts.append(l("sync.run.up-to-date"))
        case .succeeded, .failed:
            break
        }
        return parts.joined(separator: l("sync.separator"))
    }

    private static func outcome(of result: MobileSyncRunResult) -> Outcome {
        switch result {
        case .succeeded: .succeeded
        case .pulledOnly, .cancelled: .partial
        case .failed: .failed
        }
    }
}

extension MobileSyncRunTrigger {
    var localizedName: String {
        switch self {
        case .manual:
            l("sync.run.trigger.manual")
        case .localChange:
            l("sync.run.trigger.local-change")
        case .foreground:
            l("sync.run.trigger.foreground")
        case .periodic:
            // MobileSync syncs every 30 minutes.
            lFormat("sync.run.trigger.periodic", NumberFormatter.shared.format(30))
        case .appStart:
            l("sync.run.trigger.app-start")
        case .signIn:
            l("sync.run.trigger.sign-in")
        }
    }
}

extension MobileSyncRunError.Kind {
    /// A short reason a sync failed.
    var localizedDescription: String {
        switch self {
        case .network: l("sync.error.network")
        case .authentication: l("sync.error.authentication")
        case .server: l("sync.error.server")
        case .rejected: l("sync.error.rejected")
        case .unknown: l("sync.error.unknown")
        }
    }
}
#endif
