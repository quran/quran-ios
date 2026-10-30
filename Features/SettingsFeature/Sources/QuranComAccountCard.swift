#if QURAN_SYNC
import Foundation
import Localization
import NoorUI
import SwiftUI
import UIx

@MainActor
struct QuranComAccountCard: View {
    @ScaledMetric private var avatarSize = 48.0
    @ScaledMetric private var profileAvatarSize = 56.0
    @ScaledMetric private var statusIconSize = 22.0
    @ScaledMetric private var reviewCornerRadius = 14.0
    @ScaledMetric private var buttonHorizontalPadding = 14.0
    @ScaledMetric private var buttonVerticalPadding = 8.0
    @ScaledMetric private var cardCornerRadius = 20.0
    @ScaledMetric private var cardPadding = 16.0
    @ScaledMetric private var headerSpacing = 12.0
    @ScaledMetric private var iconCornerRadius = 14.0
    @ScaledMetric private var rowVerticalPadding = 14.0
    @ScaledMetric private var signInVerticalPadding = 12.0

    let isAuthenticated: Bool
    let profile: AccountProfile
    let status: SyncStatusSummary
    let openAccountAction: Action
    let syncNowAction: Action
    let signInAction: AsyncAction

    var body: some View {
        Group {
            if isAuthenticated {
                authenticatedContent
            } else {
                unauthenticatedContent
            }
        }
        .padding(cardPadding)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
    }

    private var unauthenticatedContent: some View {
        VStack(spacing: cardPadding) {
            HStack(alignment: .top, spacing: headerSpacing) {
                Image(systemName: "arrow.up")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: avatarSize, height: avatarSize)
                    .background(
                        Color.accentColor.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(l("setting.quran_account.sign_in"))
                        .font(.headline)
                        .foregroundStyle(Color.label)

                    Text(l("setting.quran_account.sign_in.subtitle"))
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            AsyncButton(tapPolicy: .ignoreWhileRunning, action: signInAction) {
                Text(l("setting.quran_account.sign_in"))
                    .font(.headline)
                    .foregroundStyle(Color.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, signInVerticalPadding)
                    .background(Color.accentColor, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var authenticatedContent: some View {
        VStack(spacing: 0) {
            Button(action: openAccountAction) {
                HStack(spacing: headerSpacing) {
                    AccountAvatar(profile: profile, length: profileAvatarSize)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name ?? profile.email ?? l("setting.quran_account.signed_in"))
                            .font(.headline)
                            .foregroundStyle(Color.label)

                        if profile.name != nil, let email = profile.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondaryLabel)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.tertiaryLabel)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint(l("sync.account.title"))
            .padding(.bottom, cardPadding)

            Divider()

            statusRow
                .padding(.top, rowVerticalPadding)

            if status.hasHeldItems {
                reviewHeldItems
                    .padding(.top, rowVerticalPadding)
            }
        }
    }

    private var statusRow: some View {
        HStack(spacing: headerSpacing) {
            if let icon = status.icon {
                SyncStatusIcon(icon: icon)
                    .font(.title3)
                    .frame(width: statusIconSize, height: statusIconSize)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(status.title)
                    .font(.body)
                    .foregroundStyle(titleColor)
                Text(status.detail)
                    .font(.footnote)
                    .foregroundStyle(Color.secondaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Button(action: syncNowAction) {
                Text(status.button.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, buttonHorizontalPadding)
                    .padding(.vertical, buttonVerticalPadding)
                    .background(Color.accentColor.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!status.button.isEnabled)
            .opacity(status.button.isEnabled ? 1 : 0.45)
        }
    }

    private var reviewHeldItems: some View {
        Button(action: openAccountAction) {
            HStack {
                Text(l("sync.held.review"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caution)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.caution)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, headerSpacing)
            .padding(.vertical, rowVerticalPadding)
            .background(Color.cautionBackground, in: RoundedRectangle(cornerRadius: reviewCornerRadius, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var titleColor: Color {
        switch status.tone {
        case .normal: Color.label
        case .failure: Color.red
        case .caution: Color.caution
        }
    }
}

#Preview("Signed out") {
    List {
        QuranComAccountCard(
            isAuthenticated: false,
            profile: AccountProfile(nil),
            status: SyncStatusSummary(SyncActivity(), style: .card),
            openAccountAction: {},
            syncNowAction: {},
            signInAction: {}
        )
        .listRowInsets(.zero)
        .listRowBackground(Color.clear)
    }
    .listStyle(.insetGrouped)
}

#Preview("Signed in") {
    List {
        QuranComAccountCard(
            isAuthenticated: true,
            profile: AccountProfile(.init(id: "1", name: "Aisha Rahman", email: "aisha.rahman@example.com")),
            status: SyncStatusSummary(SyncActivity(status: .succeeded(at: Date().addingTimeInterval(-120))), style: .card),
            openAccountAction: {},
            syncNowAction: {},
            signInAction: {}
        )
        .listRowInsets(.zero)
        .listRowBackground(Color.clear)
    }
    .listStyle(.insetGrouped)
}
#endif
