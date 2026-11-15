//
//  SyncRevealView.swift
//
//
//  Created by Mohamed Afifi on 2026-11-11.
//

import Localization
import SwiftUI
import UIKit
import UIx

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
                // The night the app icon reveal ends on.
                LinearGradient(
                    colors: [Palette.nightTop, Palette.nightMiddle, Palette.nightBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
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
    @ScaledMetric(relativeTo: .body) private var benefitsSpacing = 20.0
    @ScaledMetric(relativeTo: .body) private var benefitSpacing = 14.0
    @ScaledMetric(relativeTo: .body) private var benefitTextSpacing = 2.0
    @ScaledMetric(relativeTo: .body) private var benefitIconSize = 36.0
    @ScaledMetric(relativeTo: .body) private var benefitIconCornerRadius = 10.0
    /// A comfortable line length on iPad that widens with the text.
    @ScaledMetric(relativeTo: .body) private var contentMaxWidth = 440.0

    /// The design height; the button grows beyond it with its text.
    private let notNowMinHeight: CGFloat = 44
    /// What `.padding()` adds on each side of the scrolling content; keep the two in step.
    private let contentPadding: CGFloat = 16

    /// The share of the screen the stacked orbit keeps however long the copy is.
    private static let smallestStackedOrbitShare: CGFloat = 0.25

    /// The copy's measured height, so the orbit can leave it room.
    @State private var copyHeight: CGFloat?
    /// Whether the side-by-side copy and actions are taller than their viewport, measured after the
    /// first layout so the change flashes the scroll indicators.
    @State private var sideBySideOverflows = false

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
                            height: stackedOrbitHeight(screen: size.height, viewport: viewport.size.height)
                        ))
                        copy
                            .onSizeChange { copyHeight = $0.height }
                        if scrollsActions {
                            actions
                        }
                    }
                    // `contentPadding` mirrors this default padding.
                    .padding()
                    .frame(maxWidth: contentMaxWidth)
                    .frame(maxWidth: .infinity, minHeight: viewport.size.height)
                }
                .modifier(NightfallScrollBehavior(
                    flashesIndicators: stackedOverflows(screen: size.height, viewport: viewport.size.height)
                ))
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
                    .onSizeChange { sideBySideOverflows = $0.height > viewport.size.height }
                    .frame(maxWidth: .infinity, minHeight: viewport.size.height)
                }
                .modifier(NightfallScrollBehavior(flashesIndicators: sideBySideOverflows))
            }
            .frame(maxWidth: contentMaxWidth)
        }
    }

    /// The most height the stacked orbit takes: the room the copy leaves above it, within a share of
    /// the screen. Smaller at accessibility sizes, so the copy starts on screen.
    private func stackedOrbitHeight(screen: CGFloat, viewport: CGFloat) -> CGFloat {
        if scrollsActions {
            return screen * 0.3
        }
        let largest = screen * 0.45
        guard let room = roomAboveCopy(viewport: viewport) else {
            return largest
        }
        return min(largest, max(Self.smallestStackedOrbitShare * screen, room))
    }

    /// Whether the stacked copy scrolls: always once measured at accessibility sizes, where the
    /// actions scroll with it, and otherwise when even the smallest orbit leaves it too little room.
    /// It starts false, so the measurement flips it and flashes the scroll indicators.
    private func stackedOverflows(screen: CGFloat, viewport: CGFloat) -> Bool {
        guard let room = roomAboveCopy(viewport: viewport) else {
            return false
        }
        return scrollsActions || room < Self.smallestStackedOrbitShare * screen
    }

    /// The height the scrolling viewport has left above the measured copy.
    private func roomAboveCopy(viewport: CGFloat) -> CGFloat? {
        copyHeight.map { viewport - $0 - sectionSpacing - 2 * contentPadding }
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

            benefits
                .padding(.top, copySpacing)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// What signing in brings, as leading-aligned rows under the centered title.
    private var benefits: some View {
        VStack(alignment: .leading, spacing: benefitsSpacing) {
            benefit(
                systemImage: "arrow.triangle.2.circlepath",
                title: l("new.sync_reveal.every_device.title"),
                subtitle: l("new.sync_reveal.every_device.subtitle")
            )
            benefit(
                systemImage: "book",
                title: l("new.sync_reveal.go_deeper.title"),
                subtitle: l("new.sync_reveal.go_deeper.subtitle")
            )
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A gold symbol tile beside a title and its detail, read by VoiceOver as one element. At
    /// accessibility sizes the tile sits above the text, so the words keep the full width.
    private func benefit(systemImage: String, title: String, subtitle: String) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: benefitSpacing) {
                    benefitIcon(systemImage)
                    benefitText(title: title, subtitle: subtitle)
                }
            } else {
                HStack(alignment: .top, spacing: benefitSpacing) {
                    benefitIcon(systemImage)
                    benefitText(title: title, subtitle: subtitle)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func benefitIcon(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(Palette.gold)
            .frame(width: benefitIconSize, height: benefitIconSize)
            .background(
                RoundedRectangle(cornerRadius: benefitIconCornerRadius, style: .continuous)
                    .fill(Palette.gold.opacity(0.14))
            )
            .accessibilityHidden(true)
    }

    private func benefitText(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: benefitTextSpacing) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
