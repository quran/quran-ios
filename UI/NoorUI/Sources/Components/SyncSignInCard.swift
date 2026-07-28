//
//  SyncSignInCard.swift
//

import Localization
import SwiftUI
import UIx

public struct SyncSignInCard: View {
    @ScaledMetric private var actionHorizontalPadding = 14.0
    @ScaledMetric private var actionVerticalPadding = 8.0
    @ScaledMetric private var badgeCornerRadius = 12.0
    @ScaledMetric private var badgeSize = 40.0
    @ScaledMetric private var closeButtonInset = 8.0
    @ScaledMetric private var closeButtonSize = 24.0
    @ScaledMetric private var containerCornerRadius = 22.0
    @ScaledMetric private var containerPadding = 14.0
    @ScaledMetric private var contentSpacing = 10.0
    @ScaledMetric private var titleSpacing = 4.0
    @ScaledMetric private var trailingInset = 16.0

    public init(
        title: String,
        subtitle: String,
        actionLabel: String,
        dismiss: @escaping () -> Void,
        signInAction: @escaping AsyncAction
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionLabel = actionLabel
        self.dismiss = dismiss
        self.signInAction = signInAction
    }

    public var body: some View {
        HStack(spacing: contentSpacing) {
            cloudBadge

            VStack(alignment: .leading, spacing: titleSpacing) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            AsyncButton(action: signInAction) {
                Text(actionLabel)
                    .font(.headline)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, actionHorizontalPadding)
                    .padding(.vertical, actionVerticalPadding)
                    .background(Color.accentColor, in: Capsule())
            }
            .buttonStyle(.plain)
            .fixedSize()
        }
        .padding(containerPadding)
        .padding(.trailing, trailingInset)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous))
        .overlay(alignment: .topTrailing) {
            closeButton
                .padding(closeButtonInset)
        }
    }

    private let title: String
    private let subtitle: String
    private let actionLabel: String
    private let dismiss: () -> Void
    private let signInAction: AsyncAction

    private var cloudBadge: some View {
        NoorSystemImage.cloud.image
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .frame(width: badgeSize, height: badgeSize)
            .background(
                Color.accentColor.opacity(0.12),
                in: RoundedRectangle(cornerRadius: badgeCornerRadius, style: .continuous)
            )
            .accessibilityHidden(true)
    }

    private var closeButton: some View {
        Button(action: dismiss) {
            NoorSystemImage.cancel.image
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.secondaryLabel)
                .frame(width: closeButtonSize, height: closeButtonSize)
                .background(Color.systemGray5, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(lAndroid("cancel"))
    }
}

#Preview {
    SyncSignInCard(
        title: "Sync your collections",
        subtitle: "Sign in to Quran.com to keep your collections available across devices.",
        actionLabel: "Sign In",
        dismiss: {},
        signInAction: {}
    )
    .padding(10)
    .background(Color.systemGroupedBackground)
}
