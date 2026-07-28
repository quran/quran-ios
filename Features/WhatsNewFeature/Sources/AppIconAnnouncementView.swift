//
//  AppIconAnnouncementView.swift
//  Quran
//
//

import Localization
import NoorUI
import SwiftUI

@MainActor
struct AppIconAnnouncementView: View {
    @Environment(\.layoutDirection) private var layoutDirection

    @ScaledMetric(relativeTo: .body) private var actionBottomPadding = 20.0
    @ScaledMetric(relativeTo: .body) private var actionCornerRadius = 14.0
    @ScaledMetric(relativeTo: .body) private var actionHorizontalPadding = 23.5
    @ScaledMetric(relativeTo: .body) private var actionTopPadding = 5.0
    @ScaledMetric(relativeTo: .body) private var actionVerticalPadding = 14.0
    @ScaledMetric(relativeTo: .title2) private var arrowLength = 44.0
    @ScaledMetric(relativeTo: .body) private var cardCornerRadius = 20.0
    @ScaledMetric(relativeTo: .body) private var comparisonHeightAllowance = 30.0
    @ScaledMetric(relativeTo: .body) private var comparisonSpacing = 12.0
    @ScaledMetric(relativeTo: .body) private var contentSpacing = 28.0
    @ScaledMetric(relativeTo: .body) private var detailRowVerticalPadding = 12.0
    @ScaledMetric(relativeTo: .title) private var iconCornerRadius = 22.0
    @ScaledMetric(relativeTo: .caption) private var iconLabelSpacing = 10.0
    @ScaledMetric(relativeTo: .title) private var iconLength = 100.0
    @ScaledMetric(relativeTo: .title) private var iconShadowRadius = 16.0
    @ScaledMetric(relativeTo: .title) private var iconShadowYOffset = 8.0
    @ScaledMetric(relativeTo: .body) private var iconTileLength = 42.0
    @ScaledMetric(relativeTo: .body) private var introductionSpacing = 12.0
    @ScaledMetric(relativeTo: .caption) private var labelTracking = 1.2
    @ScaledMetric(relativeTo: .body) private var rowSpacing = 14.0

    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: contentSpacing) {
                    introduction
                    iconComparison
                    detailsCard
                }
                .frame(maxWidth: 440)
                .padding()
                .frame(maxWidth: .infinity)
            }

            action
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .tint(.newAppIconTint)
    }

    private var introduction: some View {
        VStack(spacing: introductionSpacing) {
            Text(l("new.icon_announcement.title"))
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Text(l("new.icon_announcement.body"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)
        }
    }

    private var iconComparison: some View {
        GeometryReader { geometry in
            let fittedArrowLength = min(arrowLength, geometry.size.width * 0.14)
            let maximumIconLength = (geometry.size.width - fittedArrowLength - comparisonSpacing * 2) / 2
            let fittedIconLength = min(iconLength, maximumIconLength)

            HStack(spacing: comparisonSpacing) {
                appIcon(
                    image: Image("app-image", bundle: .main),
                    label: l("new.icon_announcement.now"),
                    labelColor: .secondary,
                    length: fittedIconLength,
                    castsShadow: false
                )

                Image(systemName: "arrow.forward")
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: fittedArrowLength, height: fittedArrowLength)
                    .background(Color(.secondarySystemGroupedBackground), in: Circle())
                    .accessibilityHidden(true)

                appIcon(
                    image: Image("new-app-icon", bundle: .main),
                    label: l("new.icon_announcement.coming_soon"),
                    labelColor: .newAppIconTint,
                    length: fittedIconLength,
                    castsShadow: true
                )
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: iconLength + comparisonHeightAllowance)
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(
                icon: "star.fill",
                title: l("new.icon_announcement.same_app.title"),
                body: l("new.icon_announcement.same_app.body")
            )

            Divider()
                .padding(.leading, iconTileLength + rowSpacing)

            detailRow(
                icon: "clock",
                title: l("new.icon_announcement.release.title"),
                body: l("new.icon_announcement.release.body")
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
    }

    private func detailRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: rowSpacing) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(.systemBackground))
                .frame(width: iconTileLength, height: iconTileLength)
                .background(Color.newAppIconTint)
                .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius / 2, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, detailRowVerticalPadding)
    }

    private func appIcon(
        image: Image,
        label: String,
        labelColor: Color,
        length: CGFloat,
        castsShadow: Bool
    ) -> some View {
        VStack(spacing: iconLabelSpacing) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: length, height: length)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: min(iconCornerRadius, length * 0.22),
                        style: .continuous
                    )
                )
                .shadow(
                    color: castsShadow ? .black.opacity(0.3) : .clear,
                    radius: castsShadow ? iconShadowRadius : 0,
                    y: castsShadow ? iconShadowYOffset : 0
                )

            Text(label)
                .font(.caption.weight(.bold))
                .tracking(layoutDirection == .leftToRight ? labelTracking : 0)
                .foregroundStyle(labelColor)
        }
        .accessibilityElement(children: .combine)
    }

    private var action: some View {
        Button(action: onContinue) {
            Text(l("new.action"))
                .font(.headline)
                .foregroundStyle(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .padding(.vertical, actionVerticalPadding)
                .background(Color.newAppIconTint)
                .clipShape(RoundedRectangle(cornerRadius: actionCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, actionTopPadding)
        .padding(.horizontal, actionHorizontalPadding)
        .padding(.bottom, actionBottomPadding)
        .background(Color(.systemGroupedBackground))
    }
}

private extension Color {
    static var newAppIconTint: Color {
        Color("new-app-icon-accent", bundle: .main)
    }
}

#Preview {
    AppIconAnnouncementView {
    }
}
