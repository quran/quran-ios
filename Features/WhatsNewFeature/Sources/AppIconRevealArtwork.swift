//
//  AppIconRevealArtwork.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import SwiftUI

/// The night that rises from below to cover the screen, with a gold glow riding its edge.
struct AppIconRevealNight: View {
    // MARK: Internal

    let size: CGSize
    let isRisen: Bool
    let isHorizonGlowVisible: Bool

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Palette.nightTop.opacity(0), Palette.nightTop],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: edgeHeight)

            LinearGradient(
                colors: [Palette.nightTop, Palette.nightMiddle, Palette.nightBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(alignment: .top) {
                horizonGlow
            }
        }
        .frame(height: size.height + edgeHeight)
        .offset(y: isRisen ? -edgeHeight : size.height)
        .frame(width: size.width, height: size.height, alignment: .top)
    }

    // MARK: Private

    private typealias Palette = AppIconRevealPalette

    /// The soft transparent top edge.
    private let edgeHeight: CGFloat = 160

    private var horizonGlow: some View {
        EllipticalGradient(
            colors: [Palette.gold.opacity(0.5), Palette.gold.opacity(0.16), Palette.gold.opacity(0)],
            center: .center
        )
        .frame(width: size.width * 1.4, height: edgeHeight * 1.6)
        .offset(y: -edgeHeight * 0.8)
        .opacity(isHorizonGlowVisible ? 1 : 0)
    }
}

/// The previous icon, which fades, blurs, and shrinks as night falls.
struct AppIconRevealPreviousIcon: View {
    // MARK: Internal

    let isVisible: Bool
    /// The crossfade path hides the icon without motion.
    let hidesWithMotion: Bool

    var body: some View {
        Image("previous-app-icon", bundle: .main)
            .resizable()
            .scaledToFit()
            .frame(width: length, height: length)
            .clipShape(RoundedRectangle(cornerRadius: length * cornerRatio, style: .continuous))
            .blur(radius: isFading ? 6 : 0)
            .scaleEffect(isFading ? 0.96 : 1)
            .opacity(isVisible ? 1 : 0)
    }

    // MARK: Private

    private let length = AppIconRevealLayout.iconLength
    private let cornerRatio: CGFloat = 0.224

    private var isFading: Bool {
        hidesWithMotion && !isVisible
    }
}

/// The new icon: a navy tile whose gold glyph writes in from right to left,
/// a sheen across the glass, then the real icon on top.
struct AppIconRevealIcon: View {
    // MARK: Internal

    let newIcon: Image
    let isTileVisible: Bool
    let glyphProgress: CGFloat
    let isPenLit: Bool
    let isPenDone: Bool
    let sheenProgress: CGFloat
    let isNewIconVisible: Bool
    let isGlowVisible: Bool

    var body: some View {
        ZStack {
            tile
            glyph
            pen
            sheen
            finalIcon
        }
        .frame(width: length, height: length)
        // A background keeps the larger glow from resizing the icon.
        .background(glow)
        // The glyph follows Arabic writing direction in every locale.
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: Private

    private typealias Palette = AppIconRevealPalette

    private let length = AppIconRevealLayout.iconLength
    /// Matches the corners of the new icon art, so the drawn tile hides under it.
    private let cornerRatio: CGFloat = 0.26
    private let penSize = CGSize(width: 40, height: 104)
    private let sheenWidth: CGFloat = 36

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: length * cornerRatio, style: .continuous)
    }

    private var glow: some View {
        RadialGradient(
            colors: [Palette.gold.opacity(0.34), Palette.gold.opacity(0.1), Palette.gold.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: length * 1.1
        )
        .frame(width: length * 2.4, height: length * 2.4)
        .opacity(isGlowVisible ? 1 : 0)
    }

    private var tile: some View {
        shape
            .fill(LinearGradient(
                colors: [Palette.tileTop, Palette.tileMiddle, Palette.tileBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
            .overlay(shape.strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
            .frame(width: length, height: length)
            .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
            .opacity(isTileVisible ? 1 : 0)
    }

    private var glyph: some View {
        LinearGradient(
            colors: [Palette.goldLight, Palette.gold, Palette.goldDark],
            startPoint: .top,
            endPoint: .bottom
        )
        .mask(
            Image("app-glyph", bundle: .main)
                .resizable()
                .scaledToFit()
        )
        .frame(width: length, height: length)
        // The mask's left edge moves from the right side to the left side.
        .mask(alignment: .trailing) {
            Rectangle()
                .frame(width: length * glyphProgress)
        }
    }

    private var pen: some View {
        EllipticalGradient(
            colors: [Palette.cream, Palette.gold.opacity(0.7), Palette.gold.opacity(0)],
            center: .center
        )
        .frame(width: penSize.width, height: penSize.height)
        .blur(radius: 6)
        .offset(x: length / 2 - length * glyphProgress)
        // Separate modifiers let the fade-in and fade-out run as independent delayed animations.
        .opacity(isPenLit ? 1 : 0)
        .opacity(isPenDone ? 0 : 1)
    }

    private var sheen: some View {
        LinearGradient(
            colors: [.white.opacity(0), .white.opacity(0.42), .white.opacity(0)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: sheenWidth, height: length * 2)
        .rotationEffect(.degrees(20))
        .offset(x: length * (2 * sheenProgress - 1))
        .frame(width: length, height: length)
        .clipShape(shape)
        .blendMode(.plusLighter)
    }

    private var finalIcon: some View {
        newIcon
            .resizable()
            .scaledToFit()
            .frame(width: length, height: length)
            // The icon's default look, whatever the app's appearance setting;
            // the Home Screen follows the system appearance, not the app's.
            .environment(\.colorScheme, .light)
            .opacity(isNewIconVisible ? 1 : 0)
    }
}
