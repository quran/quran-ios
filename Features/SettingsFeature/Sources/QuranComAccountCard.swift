#if QURAN_SYNC
import Foundation
import Localization
import MobileSync
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

    let accountState: QuranComAccountState
    let status: SyncStatusSummary
    let openAccountAction: Action
    let syncNowAction: Action
    let signInAction: AsyncAction

    var body: some View {
        Group {
            switch accountState {
            case .unknown:
                placeholderContent
            case .signedOut:
                unauthenticatedContent
            case .signedIn(let user):
                authenticatedContent(profile: AccountProfile(user))
            }
        }
        .padding(cardPadding)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
    }

    /// The signed-in layout, redacted, until MobileSync has read the stored session, so a signed-in user never
    /// sees the sign-in card first.
    private var placeholderContent: some View {
        // A name and an email line, like a typical profile; redacted, so the text never shows.
        let text = l("setting.quran_account.signed_in")
        return authenticatedContent(profile: AccountProfile(MobileSyncUser(id: "", name: text, email: text)))
            .redacted(reason: .placeholder)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(lAndroid("loading"))
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

    private func authenticatedContent(profile: AccountProfile) -> some View {
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

#Preview("Restoring") {
    List {
        QuranComAccountCard(
            accountState: .unknown,
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

#Preview("Signed out") {
    List {
        QuranComAccountCard(
            accountState: .signedOut,
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
            accountState: .signedIn(.init(id: "1", name: "Aisha Rahman", email: "aisha.rahman@example.com")),
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
