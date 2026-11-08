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
                    iconAndText
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
                }
            }
        }
        .padding()
        .toastBackground()
        .padding(.horizontal)
    }

    // MARK: Private

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .subheadline) private var actionHorizontalPadding = 14.0
    @ScaledMetric(relativeTo: .subheadline) private var actionVerticalPadding = 7.0
    @ScaledMetric private var contentSpacing = 12.0
    @ScaledMetric(relativeTo: .title3) private var iconSlotWidth = 30.0
    @ScaledMetric private var titleSpacing = 2.0

    private var iconAndText: some View {
        HStack(spacing: contentSpacing) {
            if let icon = toast.icon {
                iconImage(icon)
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
            .dismissibleWithVoiceOver(dismiss)

            Spacer(minLength: 0)
        }
    }

    private func iconImage(_ icon: Toast.Icon) -> some View {
        icon.systemImage.image
            .font(.title3.weight(.semibold))
            .foregroundStyle(icon.color ?? Color.label)
            .frame(width: iconSlotWidth)
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
        .dismissibleWithVoiceOver(dismiss)
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

    /// VoiceOver can't swipe the toast down, so its escape gesture and a Close action dismiss it.
    func dismissibleWithVoiceOver(_ dismiss: @escaping () -> Void) -> some View {
        accessibilityAction(.escape, dismiss)
            .accessibilityAction(named: l("button.close"), dismiss)
    }

    @ViewBuilder
    func toastBackground() -> some View {
        let cornerRadius: CGFloat = 28
        let shadowOffset: CGFloat = 6
        let shadowRadius: CGFloat = 16
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
                icon: Toast.Icon(.cloud)
            ),
            dismiss: {}
        )
        Spacer()
    }
    .background(LinearGradient(colors: [.orange, .teal], startPoint: .top, endPoint: .bottom))
}
