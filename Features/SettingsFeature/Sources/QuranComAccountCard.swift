#if QURAN_SYNC
import Foundation
import Localization
import NoorUI
import SwiftUI
import UIx

@MainActor
struct QuranComAccountCard: View {
    @ScaledMetric private var avatarSize = 48.0
    @ScaledMetric private var cardCornerRadius = 20.0
    @ScaledMetric private var cardPadding = 16.0
    @ScaledMetric private var headerSpacing = 12.0
    @ScaledMetric private var iconCornerRadius = 14.0
    @ScaledMetric private var rowVerticalPadding = 14.0
    @ScaledMetric private var signInVerticalPadding = 12.0

    let isAuthenticated: Bool
    let email: String?
    let manageAccountAction: AsyncAction
    let signInAction: AsyncAction
    let signOutAction: AsyncAction

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

            AsyncButton(action: signInAction) {
                Text(l("setting.quran_account.sign_in"))
                    .font(.headline)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, signInVerticalPadding)
                    .background(Color.accentColor, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var authenticatedContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: headerSpacing) {
                Text(accountInitial)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: avatarSize, height: avatarSize)
                    .background(Color.accentColor.opacity(0.1), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(l("setting.quran_account.signed_in"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .textCase(.uppercase)

                    Text(email ?? l("setting.quran_account.profile"))
                        .font(.subheadline)
                        .foregroundStyle(Color.label)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.bottom, cardPadding)

            Divider()

            AsyncButton(action: manageAccountAction) {
                HStack {
                    Text(l("setting.quran_account.profile"))
                        .foregroundStyle(Color.label)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.tertiaryLabel)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .padding(.vertical, rowVerticalPadding)
            }
            .buttonStyle(.plain)

            Divider()

            AsyncButton(action: signOutAction) {
                Text(l("setting.quran_account.sign_out"))
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .padding(.top, rowVerticalPadding)
            }
            .buttonStyle(.plain)
        }
    }

    private var accountInitial: String {
        guard let firstCharacter = email?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .first
        else {
            return "Q"
        }
        return String(firstCharacter).uppercased()
    }
}

#Preview("Signed out") {
    List {
        QuranComAccountCard(
            isAuthenticated: false,
            email: nil,
            manageAccountAction: {},
            signInAction: {},
            signOutAction: {}
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
            email: "user@example.com",
            manageAccountAction: {},
            signInAction: {},
            signOutAction: {}
        )
        .listRowInsets(.zero)
        .listRowBackground(Color.clear)
    }
    .listStyle(.insetGrouped)
}
#endif
