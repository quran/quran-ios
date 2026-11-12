//
//  SyncRevealView.swift
//
//
//  Created by Mohamed Afifi on 2026-11-11.
//

import Localization
import SwiftUI
import UIKit

/// Tells people updating from 3.0 that sync moved from iCloud to Quran.com, on the "Nightfall" sky.
///
/// It looks the same whatever the app accent or appearance. Its copy scrolls at large text sizes,
/// and in landscape on iPhone the orbit sits beside the copy.
@MainActor
struct SyncRevealView: View {
    // MARK: Internal

    /// The app's default icon, at the center of the orbit.
    let icon: Image
    let onSignIn: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Palette.night
                    .ignoresSafeArea()
                NightfallStars()
                    .ignoresSafeArea()

                if verticalSizeClass == .compact, geometry.size.width > geometry.size.height {
                    sideBySide(geometry.size)
                } else {
                    stacked(geometry.size)
                }
            }
        }
        .environment(\.colorScheme, .dark)
    }

    // MARK: Private

    private typealias Palette = NightfallPalette

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.layoutDirection) private var layoutDirection

    @ScaledMetric(relativeTo: .largeTitle) private var sectionSpacing = 28.0
    @ScaledMetric(relativeTo: .body) private var copySpacing = 12.0
    @ScaledMetric(relativeTo: .footnote) private var chipHorizontalPadding = 12.0
    @ScaledMetric(relativeTo: .footnote) private var chipVerticalPadding = 6.0
    @ScaledMetric(relativeTo: .footnote) private var chipCornerRadius = 14.0
    @ScaledMetric(relativeTo: .body) private var actionsSpacing = 2.0
    @ScaledMetric(relativeTo: .body) private var notNowVerticalPadding = 7.0
    @ScaledMetric(relativeTo: .subheadline) private var checkSpacing = 6.0
    /// A comfortable line length on iPad that widens with the text.
    @ScaledMetric(relativeTo: .body) private var contentMaxWidth = 440.0

    /// The design height; the button grows beyond it with its text.
    private let notNowMinHeight: CGFloat = 44

    /// Actions scroll with the copy at accessibility sizes, so they never cover it.
    private var scrollsActions: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    // MARK: Layout

    private func stacked(_ size: CGSize) -> some View {
        VStack(spacing: 0) {
            GeometryReader { viewport in
                ScrollView {
                    VStack(spacing: sectionSpacing) {
                        orbit(fitting: CGSize(
                            width: size.width,
                            // Smaller at accessibility sizes, so the copy starts on screen.
                            height: scrollsActions ? size.height * 0.3 : size.height * 0.45
                        ))
                        copy
                        if scrollsActions {
                            actions
                        }
                    }
                    .padding()
                    .frame(maxWidth: contentMaxWidth)
                    .frame(maxWidth: .infinity, minHeight: viewport.size.height)
                }
                .modifier(NightfallScrollBehavior(flashesIndicators: scrollsActions))
            }

            if !scrollsActions {
                actions
                    .padding(.horizontal)
                    .padding(.bottom)
                    .frame(maxWidth: contentMaxWidth)
            }
        }
    }

    private func sideBySide(_ size: CGSize) -> some View {
        HStack(spacing: 0) {
            orbit(fitting: CGSize(width: size.width / 2, height: size.height))
                .frame(maxWidth: .infinity)

            GeometryReader { viewport in
                ScrollView {
                    VStack(spacing: sectionSpacing) {
                        copy
                        actions
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: viewport.size.height)
                }
                .modifier(NightfallScrollBehavior(flashesIndicators: true))
            }
            .frame(maxWidth: contentMaxWidth)
        }
    }

    /// The orbit at its design size, or smaller to fit `space`.
    private func orbit(fitting space: CGSize) -> some View {
        let full = SyncRevealOrbit.size
        let scale = min(1, space.width / full.width, space.height / full.height)
        return SyncRevealOrbit(icon: icon)
            .scaleEffect(scale)
            .frame(width: full.width * scale, height: full.height * scale)
    }

    // MARK: Copy

    private var copy: some View {
        VStack(spacing: copySpacing) {
            chip

            Text(l("new.sync_reveal.title"))
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(Palette.gold)
                .accessibilityAddTraits(.isHeader)

            Text(l("new.sync_reveal.body"))
                .font(.callout)
                .foregroundStyle(Color.white.opacity(0.8))

            HStack(alignment: .firstTextBaseline, spacing: checkSpacing) {
                Image(systemName: "checkmark")
                    .foregroundStyle(Palette.gold)
                    .accessibilityHidden(true)
                Text(l("new.sync_reveal.still_here"))
                    .foregroundStyle(Color.white)
            }
            .font(.subheadline.weight(.semibold))
            .accessibilityElement(children: .combine)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// "Moving from iCloud → Quran.com", read by VoiceOver as one sentence.
    private var chip: some View {
        let shape = RoundedRectangle(cornerRadius: chipCornerRadius, style: .continuous)
        let cloud = Image(systemName: "icloud")
        let phrase = l("new.sync_reveal.chip.from_icloud")
        // A forward arrow points from iCloud to Quran.com in either reading direction.
        let arrow = Image(systemName: "arrow.forward")
        let destination = "Quran.com"
        // One text, so the chip wraps like a sentence at large sizes. Interpolated values are isolated,
        // so the direction marks are part of the literal: they set the reading direction and keep the
        // arrow between the phrase and "Quran.com" instead of joining "iCloud" and "Quran.com".
        let text = layoutDirection == .rightToLeft
            ? Text("\u{200F}\(cloud) \(phrase)\u{200F} \(arrow) \u{200F}\(destination)")
            : Text("\u{200E}\(cloud) \(phrase)\u{200E} \(arrow) \u{200E}\(destination)")
        return text
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Palette.gold)
            .padding(.horizontal, chipHorizontalPadding)
            .padding(.vertical, chipVerticalPadding)
            .background(shape.fill(Palette.gold.opacity(0.14)))
            .overlay(shape.strokeBorder(Palette.gold.opacity(0.5), lineWidth: 0.5))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(l("new.sync_reveal.chip.accessibility"))
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: actionsSpacing) {
            NightfallPrimaryButton(title: l("new.sync_reveal.sign_in"), action: onSignIn)

            Button(action: onNotNow) {
                Text(l("new.sync_reveal.not_now"))
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.white)
                    .padding(.vertical, notNowVerticalPadding)
                    .frame(maxWidth: .infinity, minHeight: notNowMinHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(l(Self.footnoteKey))
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.62))
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Names the device the bookmarks stay on.
    private static var footnoteKey: String {
        if ProcessInfo.processInfo.isiOSAppOnMac || ProcessInfo.processInfo.isMacCatalystApp {
            return "new.sync_reveal.footnote.mac"
        }
        switch UIDevice.current.userInterfaceIdiom {
        case .pad: return "new.sync_reveal.footnote.ipad"
        default: return "new.sync_reveal.footnote.iphone"
        }
    }
}

#Preview {
    SyncRevealView(icon: Image(systemName: "app.fill"), onSignIn: {}, onNotNow: {})
}
