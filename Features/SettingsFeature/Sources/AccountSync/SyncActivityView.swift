#if QURAN_SYNC
//
//  SyncActivityView.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import Localization
import NoorUI
import SwiftUI
import UIx

struct SyncActivityView: View {
    @StateObject var viewModel: SyncActivityViewModel

    var body: some View {
        SyncActivityViewUI(
            activity: viewModel.activity,
            heldRows: viewModel.heldRows,
            runs: viewModel.runs,
            start: { await viewModel.start() },
            syncNow: { viewModel.syncNow() },
            edit: { await viewModel.editor.edit($0) }
        )
        .heldItemEditing(viewModel.editor)
    }
}

private struct SyncActivityViewUI: View {
    let activity: SyncActivity
    let heldRows: [HeldItemRow]
    let runs: [SyncRunRow]
    let start: AsyncAction
    let syncNow: Action
    let edit: @MainActor (HeldItemRow.Edit) async -> Void

    var body: some View {
        NoorList {
            Section {
                // Refreshes "Synced 2 minutes ago".
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    SyncStatusView(summary: SyncStatusSummary(activity), syncNow: syncNow)
                }
            }

            if !heldRows.isEmpty {
                NoorBasicSection(
                    title: lFormat("sync.held.header", NumberFormatter.shared.format(heldRows.count)),
                    footer: l("sync.held.footer")
                ) {
                    ForEach(heldRows) { row in
                        HeldItemRowView(row: row) {
                            if let rowEdit = row.edit {
                                HeldItemEditButton(edit: rowEdit, action: edit)
                            }
                        }
                    }
                }
            }

            NoorBasicSection(
                title: l("sync.runs.header"),
                footer: runs.isEmpty ? nil : lFormat("sync.activity.footer", NumberFormatter.shared.format(Self.historyLimit))
            ) {
                if runs.isEmpty {
                    NoSyncRunsView()
                } else {
                    ForEach(runs) { run in
                        SyncRunRowView(row: run)
                    }
                }
            }
        }
        .task { await start() }
    }

    /// How many runs MobileSync keeps.
    private static let historyLimit = 100
}

#Preview {
    SyncActivityViewUI(
        activity: SyncActivity(status: .succeeded(at: Date().addingTimeInterval(-120))),
        heldRows: [],
        runs: [
            SyncRunRow(.init(
                startedAt: Date().addingTimeInterval(-125),
                endedAt: Date().addingTimeInterval(-120),
                trigger: .manual,
                result: .succeeded,
                attempts: 1,
                pushed: 3,
                pulled: 1,
                held: 0,
                error: nil
            )),
        ],
        start: {},
        syncNow: {},
        edit: { _ in }
    )
}
#endif
