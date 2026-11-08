//
//  IntroTipCard.swift
//

import Localization
import SwiftUI
import UIx

/// A short, dismissible tip that introduces a screen, on a lightly tinted card.
public struct IntroTipCard: View {
    @ScaledMetric private var closeButtonSize = 24.0
    @ScaledMetric private var closeButtonHitSize = 44.0
    @ScaledMetric private var containerCornerRadius = 16.0
    @ScaledMetric private var containerPadding = 14.0
    @ScaledMetric private var contentSpacing = 12.0

    public init(image: NoorSystemImage, text: String, dismiss: @escaping () -> Void) {
        self.image = image
        self.text = text
        self.dismiss = dismiss
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: contentSpacing) {
            image.image
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            closeButton
        }
        .padding(containerPadding)
        .background(
            Color.accentColor.opacity(0.12),
            in: RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous)
        )
    }

    private let image: NoorSystemImage
    private let text: String
    private let dismiss: () -> Void

    private var closeButton: some View {
        Button(action: dismiss) {
            NoorSystemImage.cancel.image
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.secondaryLabel)
                .frame(width: closeButtonSize, height: closeButtonSize)
                .frame(width: closeButtonHitSize, height: closeButtonHitSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Grows the tap target to 44pt without making the card taller or pushing the text inward.
        .padding(-(closeButtonHitSize - closeButtonSize) / 2)
        .accessibilityLabel(l("button.close"))
    }
}

#Preview {
    IntroTipCard(
        image: .starFilled,
        text: "Save ayahs to Favorites or your own collections, like Duas or Hifz review. Highlight colors are here too.",
        dismiss: {}
    )
    .padding()
    .background(Color.systemGroupedBackground)
}
