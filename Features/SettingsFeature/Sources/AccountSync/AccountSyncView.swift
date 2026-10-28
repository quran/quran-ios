#if QURAN_SYNC
//
//  AccountSyncView.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import Localization
import NoorUI
import SwiftUI
import UIx

struct AccountSyncView: View {
    @StateObject var viewModel: AccountSyncViewModel

    var body: some View {
        AccountSyncViewUI(
            profile: AccountProfile(viewModel.user),
            activity: viewModel.activity,
            heldRows: viewModel.heldRows,
            recentRuns: viewModel.recentRuns,
            error: $viewModel.error,
            start: { await viewModel.start() },
            syncNow: { viewModel.syncNow() },
            showActivity: { viewModel.showActivity() },
            openProfile: { viewModel.openQuranComProfile() },
            signOut: { await viewModel.requestSignOut() }
        )
        .signOutConfirmation(
            isPresented: $viewModel.isSignOutConfirmationPresented,
            unsyncedCount: viewModel.unsyncedCount,
            syncNow: { viewModel.syncNow() },
            signOut: { await viewModel.signOutOfQuranCom() }
        )
    }
}

private struct AccountSyncViewUI: View {
    // MARK: Internal

    let profile: AccountProfile
    let activity: SyncActivity
    let heldRows: [HeldItemRow]
    let recentRuns: [SyncRunRow]
    @Binding var error: Error?
    let start: AsyncAction
    let syncNow: Action
    let showActivity: Action
    let openProfile: Action
    let signOut: AsyncAction

    var body: some View {
        NoorList {
            Section {
                header
                    .listRowBackground(Color.clear)
            }

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
                    ForEach(heldRows.prefix(AccountSyncViewModel.previewCount)) { row in
                        HeldItemRowView(row: row)
                    }
                    if heldRows.count > AccountSyncViewModel.previewCount {
                        SyncLinkRow(
                            title: lFormat("sync.held.show-all", NumberFormatter.shared.format(heldRows.count)),
                            action: showActivity,
                            background: Color.cautionBackground
                        )
                    }
                }
            }

            NoorBasicSection(title: l("sync.runs.header")) {
                if recentRuns.isEmpty {
                    NoSyncRunsView()
                } else {
                    ForEach(recentRuns) { run in
                        SyncRunRowView(row: run)
                    }
                    SyncLinkRow(title: l("sync.runs.see-all"), action: showActivity)
                }
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.profile),
                    title: .text(l("setting.quran_account.profile")),
                    accessory: .image(.externalLink, color: Color.tertiaryLabel),
                    action: .sync { openProfile() }
                )

                NoorListItem(
                    image: .init(.signOut, color: .red),
                    title: .text(l("setting.quran_account.sign_out")),
                    titleColor: .red,
                    action: .async { await signOut() }
                )
            }
        }
        .task { await start() }
        .errorAlert(error: $error)
        .noorListIconColumn()
    }

    // MARK: Private

    @ScaledMetric private var avatarLength = 88.0
    @ScaledMetric private var headerSpacing = 6.0

    private var header: some View {
        VStack(spacing: headerSpacing) {
            AccountAvatar(profile: profile, length: avatarLength)
                .padding(.bottom, headerSpacing)

            if let name = profile.name {
                Text(name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.label)
            }

            if let email = profile.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryLabel)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AccountSyncViewUI(
        profile: AccountProfile(.init(id: "1", name: "Aisha Rahman", email: "aisha.rahman@example.com")),
        activity: SyncActivity(
            status: .succeeded(at: Date().addingTimeInterval(-120)),
            runs: [
                .init(
                    startedAt: Date().addingTimeInterval(-125),
                    endedAt: Date().addingTimeInterval(-120),
                    trigger: .manual,
                    result: .succeeded,
                    attempts: 1,
                    pushed: 3,
                    pulled: 1,
                    held: 0,
                    error: nil
                ),
            ],
            heldItems: []
        ),
        heldRows: [],
        recentRuns: [
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
        error: .constant(nil),
        start: {},
        syncNow: {},
        showActivity: {},
        openProfile: {},
        signOut: {}
    )
}
#endif
