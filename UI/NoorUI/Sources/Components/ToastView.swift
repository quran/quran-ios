//
//  ToastView.swift
//
//
//  Created by Mohamed Afifi on 2026-11-07.
//

import Localization
import SwiftUI
import UIx

struct ToastView: View {
    // MARK: Internal

    let toast: Toast
    let dismiss: () -> Void

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // The text gets the full width; the action moves under it.
                VStack(alignment: .trailing, spacing: contentSpacing) {
                    HStack(alignment: .top, spacing: contentSpacing) {
                        iconAndText
                        dismissButtonIfShown
                    }
                    if let action = toast.action {
                        actionButton(action)
                    }
                }
            } else {
                HStack(spacing: contentSpacing) {
                    iconAndText
                    if let action = toast.action {
                        actionButton(action)
                            .fixedSize()
                    }
                    dismissButtonIfShown
                }
            }
        }
        .padding()
        .toastBackground(cornerRadius: Self.cornerRadius, shadowRadius: Self.shadowRadius, shadowOffset: Self.shadowOffset)
        .padding(.horizontal)
    }

    // MARK: Private

    private static let cornerRadius: CGFloat = 28
    private static let shadowOffset: CGFloat = 6
    private static let shadowRadius: CGFloat = 16

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .subheadline) private var actionHorizontalPadding = 14.0
    @ScaledMetric(relativeTo: .subheadline) private var actionVerticalPadding = 7.0
    @ScaledMetric private var contentSpacing = 12.0
    @ScaledMetric private var dismissButtonSize = 28.0
    @ScaledMetric private var dismissHitTargetSize = 44.0
    @ScaledMetric private var iconTileSize = 36.0
    @ScaledMetric private var titleSpacing = 2.0

    private var iconAndText: some View {
        HStack(spacing: contentSpacing) {
            if let icon = toast.icon {
                iconTile(icon)
            }

            VStack(alignment: .leading, spacing: titleSpacing) {
                toast.message.view(ofSize: .subheadline)
                    .semiboldWeight()
                    .foregroundColor(.label)
                if let subtitle = toast.subtitle {
                    subtitle.view(ofSize: .footnote)
                        .foregroundColor(.secondaryLabel)
                }
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder private var dismissButtonIfShown: some View {
        if toast.showsDismissButton {
            Button(action: dismiss) {
                NoorSystemImage.cancel.image
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.secondaryLabel)
                    .frame(width: dismissButtonSize, height: dismissButtonSize)
                    .background(Color.systemGray5, in: Circle())
                    .frame(minWidth: dismissHitTargetSize, minHeight: dismissHitTargetSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(l("button.close"))
        }
    }

    private func iconTile(_ icon: Toast.Icon) -> some View {
        let color = icon.color ?? .accentColor
        return icon.systemImage.image
            .font(.body.weight(.semibold))
            .foregroundStyle(color)
            .frame(width: iconTileSize, height: iconTileSize)
            .background(color.opacity(0.15), in: Circle())
            .accessibilityHidden(true)
    }

    private func actionButton(_ action: ToastAction) -> some View {
        Button {
            action.handler()
            dismiss()
        } label: {
            Text(action.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.onAccent)
                .padding(.horizontal, actionHorizontalPadding)
                .padding(.vertical, actionVerticalPadding)
                .background(Color.accentColor, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    /// `MultipartText` sets each part's font, so the weight is applied on top of it,
    /// which needs iOS 16.
    @ViewBuilder
    func semiboldWeight() -> some View {
        if #available(iOS 16.0, *) {
            fontWeight(.semibold)
        } else {
            self
        }
    }

    @ViewBuilder
    func toastBackground(cornerRadius: CGFloat, shadowRadius: CGFloat, shadowOffset: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        // Matches the audio banner: glassEffect can fail at runtime on iOS 26.0.
        if #available(iOS 26.1, *) {
            glassEffect(in: shape)
        } else {
            background(
                shape
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.15), radius: shadowRadius, y: shadowOffset)
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        Spacer()
        ToastView(toast: Toast("Bookmark removed"), dismiss: {})
        ToastView(
            toast: Toast(
                "Moved bookmark to page 42",
                icon: Toast.Icon(.bookmark, color: .red),
                action: ToastAction(title: "Undo", handler: {})
            ),
            dismiss: {}
        )
        ToastView(
            toast: Toast(
                "Playing",
                subtitle: "Al-Fatihah 1 to Al-Fatihah 7",
                icon: Toast.Icon(.play),
                action: ToastAction(title: "Modify", handler: {})
            ),
            dismiss: {}
        )
        ToastView(
            toast: Toast(
                "Sync is on",
                subtitle: "Your bookmarks and notes stay up to date on every device.",
                icon: Toast.Icon(.cloud),
                showsDismissButton: true
            ),
            dismiss: {}
        )
        Spacer()
    }
    .background(LinearGradient(colors: [.orange, .teal], startPoint: .top, endPoint: .bottom))
}
