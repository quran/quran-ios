//
//  TipCard.swift
//

import Localization
import SwiftUI
import UIx

/// A dismissible card that points the user to something, with an optional action.
public struct TipCard: View {
    // MARK: Lifecycle

    public init(
        title: String,
        text: String,
        image: NoorSystemImage,
        action: Action? = nil,
        dismiss: @escaping () -> Void
    ) {
        self.init(title: title, text: text, action: action, dismiss: dismiss) {
            image.image
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
    }

    /// Shows a custom icon in the system image's slot.
    public init(
        title: String,
        text: String,
        action: Action? = nil,
        dismiss: @escaping () -> Void,
        @ViewBuilder icon: () -> some View
    ) {
        self.title = title
        self.text = text
        self.icon = AnyView(icon())
        self.action = action
        self.dismiss = dismiss
    }

    // MARK: Public

    public struct Action {
        // MARK: Lifecycle

        public init(_ title: String, perform: @escaping () -> Void) {
            self.title = title
            self.perform = perform
        }

        // MARK: Internal

        let title: String
        let perform: () -> Void
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        iconSlot
                        Spacer(minLength: 0)
                        dismissButton
                    }
                    content
                }
            } else {
                HStack(alignment: .top) {
                    iconSlot
                    content
                    dismissButton
                }
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: Private

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric private var imageSize = 36.0
    @ScaledMetric private var dismissSize = 24.0
    @ScaledMetric private var dismissTargetSize = 44.0
    @ScaledMetric private var cornerRadius = 20.0
    @ScaledMetric private var textSpacing = 4.0

    private let title: String
    private let text: String
    private let icon: AnyView
    private let action: Action?
    private let dismiss: () -> Void

    private var iconSlot: some View {
        icon
            .frame(width: imageSize, height: imageSize)
            .accessibilityHidden(true)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: textSpacing) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.label)
                .accessibilityAddTraits(.isHeader)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.secondaryLabel)

            if let action {
                AccentCapsuleButton(action.title, action: action.perform)
                    .padding(.top, textSpacing)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dismissButton: some View {
        Button(action: dismiss) {
            NoorSystemImage.cancel.image
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.secondaryLabel)
                .frame(width: dismissSize, height: dismissSize)
                .background(Color.systemGray5, in: Circle())
                .frame(minWidth: dismissTargetSize, minHeight: dismissTargetSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(l("button.close"))
    }
}

#Preview {
    VStack {
        TipCard(
            title: "A tip with an action",
            text: "It points to something new and offers a way to see it.",
            image: .bookmark,
            action: TipCard.Action("Show Me") {},
            dismiss: {}
        )
        TipCard(
            title: "A tip without an action",
            text: "Close it when you're done.",
            image: .bookmark,
            dismiss: {}
        )
        TipCard(
            title: "A tip with a custom icon",
            text: "The icon takes the same slot, so the text lines up.",
            dismiss: {}
        ) {
            HighlightPaletteIcon(size: 24)
        }
    }
    .padding()
    .frame(maxHeight: .infinity)
    .background(Color.systemGroupedBackground)
}
