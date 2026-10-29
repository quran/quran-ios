#if QURAN_SYNC
//
//  SyncActivityRows.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import Localization
import NoorUI
import SwiftUI
import UIx

/// The sync status and its Sync now button.
struct SyncStatusView: View {
    // MARK: Internal

    let summary: SyncStatusSummary
    let syncNow: Action

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack(spacing: iconSpacing) {
                if let icon = summary.icon {
                    SyncStatusIcon(icon: icon)
                        .frame(width: iconLength, height: iconLength)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(summary.title)
                        .font(.body)
                        .foregroundStyle(Color.label)
                    Text(summary.detail)
                        .font(.footnote)
                        .foregroundStyle(Color.secondaryLabel)
                }
                .accessibilityElement(children: .combine)
            }

            ProminentRoundedButton(label: summary.button.title) {
                syncNow()
            }
            .disabled(!summary.button.isEnabled)
            .opacity(summary.button.isEnabled ? 1 : 0.45)
        }
        .padding(.vertical, verticalPadding)
    }

    // MARK: Private

    @ScaledMetric private var iconLength = 22.0
    @ScaledMetric private var iconSpacing = 10.0
    @ScaledMetric private var spacing = 12.0
    @ScaledMetric private var verticalPadding = 6.0
}

struct SyncStatusIcon: View {
    let icon: SyncStatusSummary.Icon

    var body: some View {
        switch icon {
        case .synced:
            Image(systemName: "checkmark.circle")
                .foregroundStyle(Color.green)
                .accessibilityHidden(true)
        case .syncing:
            ProgressView()
                .accessibilityHidden(true)
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color.red)
                .accessibilityHidden(true)
        case .held:
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(Color.caution)
                .accessibilityHidden(true)
        }
    }
}

/// An item that doesn't sync, on the amber Not syncing card.
struct HeldItemRowView<Trailing: View>: View {
    // MARK: Lifecycle

    init(row: HeldItemRow, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.row = row
        self.trailing = trailing()
    }

    // MARK: Internal

    let row: HeldItemRow
    let trailing: Trailing

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            icon.image
                .foregroundStyle(Color.caution)
                .frame(width: iconLength, height: iconLength)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: textSpacing) {
                row.title.view(ofSize: .body)
                    .foregroundStyle(Color.label)
                Text(row.reason)
                    .font(.subheadline)
                    .foregroundStyle(Color.label)
                if let waiting = row.waiting {
                    Text(waiting)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryLabel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            trailing
        }
        .padding(.vertical, verticalPadding)
        .listRowBackground(Color.cautionBackground)
        .listRowSeparatorTint(Color.cautionSeparator)
    }

    // MARK: Private

    @ScaledMetric private var iconLength = 24.0
    @ScaledMetric private var spacing = 12.0
    @ScaledMetric private var textSpacing = 2.0
    @ScaledMetric private var verticalPadding = 4.0

    private var icon: NoorSystemImage {
        switch row.kind {
        case .note: .note
        case .collection: .starFilled
        case .bookmark: .bookmarkOutline
        }
    }
}

/// A sync run: when and why it ran, what it did, and how it ended.
struct SyncRunRowView: View {
    // MARK: Internal

    let row: SyncRunRow

    var body: some View {
        HStack(spacing: spacing) {
            outcomeIcon
                .frame(width: iconLength, height: iconLength)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: textSpacing) {
                Text(row.title)
                    .font(.body)
                    .foregroundStyle(Color.label)
                Text(row.detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, verticalPadding)
        .accessibilityElement(children: .combine)
    }

    // MARK: Private

    @ScaledMetric private var iconLength = 20.0
    @ScaledMetric private var spacing = 12.0
    @ScaledMetric private var textSpacing = 2.0
    @ScaledMetric private var verticalPadding = 4.0

    @ViewBuilder
    private var outcomeIcon: some View {
        switch row.outcome {
        case .succeeded:
            Image(systemName: "checkmark.circle").foregroundStyle(Color.green)
        case .partial:
            Image(systemName: "arrow.down.circle").foregroundStyle(Color.caution)
        case .failed:
            Image(systemName: "xmark.circle").foregroundStyle(Color.red)
        }
    }
}

/// The Recent syncs card before the first sync.
struct NoSyncRunsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text(l("sync.runs.empty.title"))
                .font(.body)
                .foregroundStyle(Color.label)
            Text(l("sync.runs.empty.body"))
                .font(.subheadline)
                .foregroundStyle(Color.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, verticalPadding)
        .accessibilityElement(children: .combine)
    }

    @ScaledMetric private var spacing = 2.0
    @ScaledMetric private var verticalPadding = 4.0
}

/// A link row at the end of a card, such as "Show all".
struct SyncLinkRow: View {
    let title: String
    let action: Action
    var background: Color?

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .listRowBackground(background)
        .listRowSeparatorTint(background == nil ? nil : Color.cautionSeparator)
    }
}
#endif
