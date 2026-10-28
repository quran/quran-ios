#if QURAN_SYNC
//
//  SyncStatusSummary.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import Foundation
import Localization
import MobileSync
import NoorUI

/// The sync status line and its button.
struct SyncStatusSummary: Equatable {
    enum Icon: Equatable {
        case synced
        case syncing
        case failed
        case held
    }

    enum Button: Equatable {
        case syncNow
        case syncing
        case tryAgain

        // MARK: Internal

        var title: String {
            switch self {
            case .syncNow: l("sync.action.sync-now")
            case .syncing: l("sync.action.syncing")
            case .tryAgain: l("sync.action.try-again")
            }
        }

        var isEnabled: Bool {
            self != .syncing
        }
    }

    // MARK: Lifecycle

    init(_ activity: SyncActivity) {
        let heldCount = activity.blockingItems.count
        let held = heldCount > 0 ? lFormat("sync.held.count", heldCount) : nil
        switch activity.state {
        case .syncing:
            icon = .syncing
            title = l("sync.status.syncing")
            detail = l("sync.status.sending")
            button = .syncing
        case .retrying(let reason):
            // The retry comes within seconds, so "soon" says enough; Try again runs it now.
            icon = .failed
            title = l("sync.status.failed")
            detail = lFormat("sync.status.retrying", reason.localizedDescription)
            button = .tryAgain
        case .failed(let reason):
            icon = .failed
            title = l("sync.status.failed")
            detail = reason?.localizedDescription ?? l("sync.error.paused")
            button = .tryAgain
        case .synced(let date):
            icon = held == nil ? .synced : .held
            title = lFormat("sync.status.synced", date.syncedTimeAgo())
            detail = held ?? l("sync.status.all-items")
            button = .syncNow
        case .neverSynced:
            icon = held == nil ? nil : .held
            title = l("sync.status.never-synced")
            detail = held ?? l("sync.status.all-items")
            button = .syncNow
        }
    }

    // MARK: Internal

    /// `nil` before the first sync.
    let icon: Icon?
    let title: String
    let detail: String
    let button: Button
}

extension Date {
    /// How long ago a sync was, saying "just now" for the last minute, where the system says "now".
    func syncedTimeAgo() -> String {
        let elapsed = Date().timeIntervalSince(self)
        // A clock a little ahead of the server's can put a sync just after now.
        if elapsed < 60, elapsed > -60 * 60 {
            return l("sync.status.just-now")
        }
        return timeAgo()
    }
}
#endif
