//
//  AppWhatsNewView.swift
//  Quran
//

import Localization
import SwiftUI
import UIKit

@MainActor
struct AppWhatsNewView: View {
    @ScaledMetric(relativeTo: .body) private var actionBottomPadding = 20.0
    @ScaledMetric(relativeTo: .body) private var actionCornerRadius = 14.0
    @ScaledMetric(relativeTo: .body) private var actionHorizontalPadding = 23.5
    @ScaledMetric(relativeTo: .body) private var actionTopPadding = 5.0
    @ScaledMetric(relativeTo: .body) private var actionVerticalPadding = 14.0
    @ScaledMetric(relativeTo: .body) private var cardCornerRadius = 22.0
    @ScaledMetric(relativeTo: .body) private var cardSpacing = 18.0
    @ScaledMetric(relativeTo: .body) private var detailSpacing = 12.0
    @ScaledMetric(relativeTo: .body) private var headerSpacing = 14.0
    @ScaledMetric(relativeTo: .body) private var iconCornerRadius = 14.0
    @ScaledMetric(relativeTo: .body) private var iconLength = 48.0

    let items: [WhatsNewItem]
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: cardSpacing) {
                ForEach(items.indices, id: \.self) { index in
                    AppWhatsNewCard(
                        item: items[index],
                        cardCornerRadius: cardCornerRadius,
                        detailSpacing: detailSpacing,
                        headerSpacing: headerSpacing,
                        iconCornerRadius: iconCornerRadius,
                        iconLength: iconLength
                    )
                }
            }
            .frame(maxWidth: 560)
            .padding()
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            action
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var action: some View {
        Button(action: onContinue) {
            Text(l("new.action"))
                .font(.headline)
                .foregroundStyle(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .padding(.vertical, actionVerticalPadding)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: actionCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, actionTopPadding)
        .padding(.horizontal, actionHorizontalPadding)
        .padding(.bottom, actionBottomPadding)
        .background(Color(.systemGroupedBackground))
    }
}

@MainActor
private struct AppWhatsNewCard: View {
    let item: WhatsNewItem
    let cardCornerRadius: CGFloat
    let detailSpacing: CGFloat
    let headerSpacing: CGFloat
    let iconCornerRadius: CGFloat
    let iconLength: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: headerSpacing) {
            HStack(spacing: headerSpacing) {
                Image(systemName: item.image)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: iconLength, height: iconLength)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous))
                    .accessibilityHidden(true)

                Text(item.localizedTitle)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: detailSpacing) {
                ForEach(item.localizedDetails.indices, id: \.self) { index in
                    detail(item.localizedDetails[index])
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func detail(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: detailSpacing) {
            Text("•")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

@MainActor
final class AppWhatsNewViewController: UIHostingController<AppWhatsNewView> {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationTitle()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureNavigationTitle()
    }

    private func configureNavigationTitle() {
        navigationItem.titleView = navigationTitleLabel
        navigationItem.largeTitleDisplayMode = .never
    }

    private lazy var navigationTitleLabel: UILabel = {
        let label = UILabel()
        label.text = l("new.title")
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.textAlignment = .center
        label.accessibilityTraits = .header
        return label
    }()
}

#Preview {
    AppWhatsNewView(
        items: [
            WhatsNewItem(
                title: "new.audio_upgrades",
                subtitle: "new.audio_upgrades.details",
                image: "speedometer"
            ),
            WhatsNewItem(
                title: "new.personalization",
                subtitle: "new.personalization.details",
                image: "paintpalette.fill"
            ),
        ],
        onContinue: {}
    )
}
