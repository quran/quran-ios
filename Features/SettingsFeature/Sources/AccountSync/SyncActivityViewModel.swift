#if QURAN_SYNC
//
//  SyncActivityViewModel.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import Foundation
import MobileSync
import VLogging

@MainActor
final class SyncActivityViewModel: ObservableObject {
    // MARK: Lifecycle

    init(quranDataService: MobileSyncDataService, editor: HeldItemEditor) {
        self.quranDataService = quranDataService
        self.editor = editor
    }

    // MARK: Internal

    /// Fixes the held items.
    let editor: HeldItemEditor

    @Published private(set) var activity = SyncActivity()
    @Published private(set) var lookup = HeldItemLookup()

    var heldRows: [HeldItemRow] {
        HeldItemRow.rows(for: activity.heldItems, lookup: lookup)
    }

    /// Every run MobileSync keeps, the newest first.
    var runs: [SyncRunRow] {
        activity.runs.map { SyncRunRow($0) }
    }

    /// Follows the sync activity until the task is cancelled.
    func start() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.observeActivity() }
            group.addTask { await self.observeLookup() }
        }
    }

    func syncNow() {
        logger.info("Quran Sync: Sync now from Sync activity")
        quranDataService.triggerSync(immediately: true)
    }

    // MARK: Private

    private let quranDataService: MobileSyncDataService

    private func observeActivity() async {
        for await change in SyncActivity.changes(of: quranDataService) {
            activity.apply(change)
        }
    }

    private func observeLookup() async {
        for await change in HeldItemLookup.changes(of: quranDataService) {
            lookup.apply(change)
        }
    }
}
#endif
