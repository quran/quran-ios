//
//  TipCard.swift
//

import Localization
import QuranAnnotations
import SwiftUI
import UIx

/// A dismissible card that points the user to something, with an optional action.
public struct TipCard: View {
    // MARK: Lifecycle

    /// - Parameters:
    ///   - imageColor: The glyph's color.
    ///   - imageBackground: The circle behind the glyph.
    ///   - actionTitle: The action button's title; without one, the card shows no button.
    public init(
        title: String,
        text: String,
        image: NoorSystemImage,
        imageColor: Color = .accentColor,
        imageBackground: Color = Color.accentColor.opacity(0.12),
        actionTitle: String? = nil,
        action: @escaping () -> Void = {},
        dismiss: @escaping () -> Void
    ) {
        self.title = title
        self.text = text
        self.image = image
        self.imageColor = imageColor
        self.imageBackground = imageBackground
        self.actionTitle = actionTitle
        self.action = action
        self.dismiss = dismiss
    }

    // MARK: Public

    public var body: some View {
        HStack(alignment: .top) {
            image.image
                .font(.body.weight(.semibold))
                .foregroundStyle(imageColor)
                .frame(width: imageSize, height: imageSize)
                .background(imageBackground, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: textSpacing) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.label)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryLabel)

                if let actionTitle {
                    AccentCapsuleButton(actionTitle, action: action)
                        .padding(.top, textSpacing)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)

            dismissButton
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: Private

    @ScaledMetric private var imageSize = 36.0
    @ScaledMetric private var dismissSize = 24.0
    @ScaledMetric private var cornerRadius = 20.0
    @ScaledMetric private var textSpacing = 4.0

    private let title: String
    private let text: String
    private let image: NoorSystemImage
    private let imageColor: Color
    private let imageBackground: Color
    private let actionTitle: String?
    private let action: () -> Void
    private let dismiss: () -> Void

    private var dismissButton: some View {
        Button(action: dismiss) {
            NoorSystemImage.cancel.image
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.secondaryLabel)
                .frame(width: dismissSize, height: dismissSize)
                .background(Color.systemGray5, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(l("button.close"))
    }
}

#Preview {
    VStack {
        TipCard(
            title: "Highlights now live in Bookmarks",
            text: "Notes keeps only what you write. Your highlighted ayahs are in the Bookmarks tab, by color.",
            image: .highlighter,
            imageColor: .black.opacity(0.75),
            imageBackground: HighlightColor.yellow.color,
            actionTitle: "Show Highlights",
            dismiss: {}
        )
        TipCard(
            title: "A tip without an action",
            text: "Close it when you're done.",
            image: .bookmark,
            dismiss: {}
        )
    }
    .padding()
    .frame(maxHeight: .infinity)
    .background(Color.systemGroupedBackground)
}
