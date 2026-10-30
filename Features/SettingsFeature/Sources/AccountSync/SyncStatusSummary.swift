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

    /// The Account & Sync screen says it all in the title; the Settings card puts the time in the detail and
    /// leads with what isn't syncing.
    enum Style {
        case screen
        case card
    }

    /// How the title reads.
    enum Tone: Equatable {
        case normal
        case failure
        case caution
    }

    // MARK: Lifecycle

    init(_ activity: SyncActivity, style: Style = .screen) {
        let heldCount = activity.blockingItems.count
        hasHeldItems = heldCount > 0
        let held = heldCount > 0 ? lFormat("sync.held.count", heldCount) : nil
        switch activity.state {
        case .syncing:
            icon = .syncing
            tone = .normal
            title = l("sync.status.syncing")
            // A sync both sends and receives, so the detail says what syncs, like the synced line.
            detail = style == .card ? l("sync.status.items.short") : l("sync.status.all-items")
            button = .syncing
        case .retrying(let reason):
            icon = .failed
            tone = .failure
            title = l("sync.status.failed")
            switch style {
            case .screen:
                // The retry comes within seconds, so "soon" says enough; Try again runs it now.
                detail = lFormat("sync.status.failed.kept", lFormat("sync.status.retrying", reason.localizedDescription))
            case .card:
                // The red title and Try again already say it isn't done; the card's line stays short beside the button.
                detail = lFormat("sync.status.failed.kept", reason.localizedDescription)
            }
            button = .tryAgain
        case .failed(let reason):
            icon = .failed
            tone = .failure
            title = l("sync.status.failed")
            // Without a reason, the latest sync only received changes, so saying they stay on this device is enough.
            detail = reason.map { lFormat("sync.status.failed.kept", $0.localizedDescription) } ?? l("sync.status.failed.kept.paused")
            button = .tryAgain
        case .synced(let date):
            icon = held == nil ? .synced : .held
            button = .syncNow
            switch (style, held) {
            case (.screen, _):
                tone = .normal
                title = lFormat("sync.status.synced", date.syncedTimeAgo())
                detail = held ?? l("sync.status.all-items")
            case (.card, nil):
                tone = .normal
                title = l("sync.status.synced.short")
                detail = lFormat("sync.status.synced.card", date.syncedTimeAgo().nonBreaking)
            case (.card, let held?):
                tone = .caution
                title = held
                detail = lFormat("sync.status.everything-else-synced", date.syncedTimeAgo().nonBreaking)
            }
        case .neverSynced:
            icon = held == nil ? nil : .held
            button = .syncNow
            switch (style, held) {
            case (.card, let held?):
                tone = .caution
                title = held
                detail = l("sync.status.never-synced")
            default:
                tone = .normal
                title = l("sync.status.never-synced")
                detail = held ?? l("sync.status.all-items")
            }
        }
    }

    // MARK: Internal

    /// `nil` before the first sync.
    let icon: Icon?
    let tone: Tone
    let title: String
    let detail: String
    let button: Button
    /// Whether items the user can fix aren't syncing, whatever the sync is doing now.
    let hasHeldItems: Bool
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

private extension String {
    /// Keeps "2 minutes ago" on one line in the card's narrow detail.
    var nonBreaking: String {
        replacingOccurrences(of: " ", with: "\u{00A0}")
    }
}
#endif
