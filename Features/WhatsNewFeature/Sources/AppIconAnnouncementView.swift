//
//  AppIconAnnouncementView.swift
//  Quran
//
//

import Localization
import SwiftUI

@MainActor
struct AppIconAnnouncementView: View {
    @ScaledMetric(relativeTo: .body) private var actionHeight = 52.0
    @ScaledMetric(relativeTo: .body) private var cardCornerRadius = 20.0
    @ScaledMetric(relativeTo: .body) private var closeButtonLength = 44.0
    @ScaledMetric(relativeTo: .body) private var comparisonSpacing = 12.0
    @ScaledMetric(relativeTo: .title) private var iconLength = 100.0
    @ScaledMetric(relativeTo: .body) private var iconTileLength = 42.0
    @ScaledMetric(relativeTo: .body) private var rowSpacing = 14.0

    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
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
        .tint(.newAppIconAccent)
    }

    private var header: some View {
        ZStack {
            Text(l("new.title"))
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: closeButtonLength, height: closeButtonLength)
                        .background(Color(.tertiarySystemFill), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(l("new.icon_announcement.close"))
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var introduction: some View {
        VStack(spacing: 12) {
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
            let arrowLength = min(closeButtonLength, geometry.size.width * 0.14)
            let maximumIconLength = (geometry.size.width - arrowLength - comparisonSpacing * 2) / 2
            let fittedIconLength = min(iconLength, maximumIconLength)

            HStack(spacing: comparisonSpacing) {
                appIcon(
                    image: Image("app-image", bundle: .main),
                    label: l("new.icon_announcement.now"),
                    labelColor: .secondary,
                    length: fittedIconLength
                )

                Image(systemName: "arrow.forward")
                    .font(.title2.bold())
                    .foregroundStyle(Color.newAppIconAccent)
                    .frame(width: arrowLength, height: arrowLength)
                    .background(Color(.secondarySystemGroupedBackground), in: Circle())
                    .accessibilityHidden(true)

                appIcon(
                    image: Image("new-app-icon", bundle: .main),
                    label: l("new.icon_announcement.coming_soon"),
                    labelColor: .newAppIconAccent,
                    length: fittedIconLength
                )
                .shadow(color: .newAppIconAccent.opacity(0.22), radius: 18, y: 8)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: iconLength + 30)
    }

    private func appIcon(image: Image, label: String, labelColor: Color, length: CGFloat) -> some View {
        VStack(spacing: 10) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: length, height: length)

            Text(label)
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(labelColor)
        }
        .accessibilityElement(children: .combine)
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
                .foregroundStyle(Color.newAppIconGold)
                .frame(width: iconTileLength, height: iconTileLength)
                .background(Color.newAppIconAccent)
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
        .padding(.vertical, 12)
    }

    private var action: some View {
        Button(action: onDismiss) {
            Text(l("new.icon_announcement.action"))
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: actionHeight)
                .background(Color.newAppIconAccent)
                .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

private extension Color {
    static var newAppIconAccent: Color {
        Color("new-app-icon-accent", bundle: .main)
    }

    static var newAppIconGold: Color {
        Color("new-app-icon-gold", bundle: .main)
    }
}

#Preview {
    AppIconAnnouncementView {
    }
}
