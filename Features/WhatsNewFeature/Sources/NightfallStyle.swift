//
//  NightfallStyle.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import SwiftUI
import UIKit
import UIx

/// The "Nightfall" reveals' fixed navy and gold, independent of the app accent and appearance.
enum NightfallPalette {
    // MARK: Internal

    static let gold = color(0xE2AF56)
    static let goldLight = color(0xF6D493)
    static let goldDark = color(0xB8893F)
    static let cream = color(0xFFF3D6)
    static let nightTop = color(0x00085A)
    static let nightMiddle = color(0x000A48)
    static let nightBottom = color(0x00062A)
    static let tileTop = color(0x000166)
    static let tileMiddle = color(0x000C52)
    static let tileBottom = color(0x00153F)
    static let continueText = color(0x000A3D)
    /// The sync reveal's flat night sky.
    static let night = color(0x0A0A36)
    /// Fills the sync reveal's device nodes, a step lighter than the night.
    static let node = color(0x14144A)

    // MARK: Private

    private static func color(_ rgb: Int) -> Color {
        Color(UIColor(rgb: rgb))
    }
}

/// The gold capsule that confirms a reveal.
struct NightfallPrimaryButton: View {
    // MARK: Internal

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(NightfallPalette.continueText)
                .padding(.horizontal)
                .padding(.vertical, verticalPadding)
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .background(NightfallPalette.gold, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Private

    @ScaledMetric(relativeTo: .headline) private var verticalPadding = 14.0

    /// The design height; the button grows beyond it with its text.
    private let minHeight: CGFloat = 52
}

/// Faint stars scattered over the night sky, placed relative to the screen so they spread on any size.
struct NightfallStars: View {
    // MARK: Internal

    var body: some View {
        GeometryReader { geometry in
            ForEach(Self.stars.indices, id: \.self) { index in
                let star = Self.stars[index]
                Circle()
                    .fill(Color.white.opacity(star.opacity))
                    .frame(width: star.diameter, height: star.diameter)
                    .position(x: star.x * geometry.size.width, y: star.y * geometry.size.height)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Private

    private struct Star {
        /// Where the star sits, as fractions of the width and height.
        let x: CGFloat
        let y: CGFloat
        let diameter: CGFloat
        let opacity: Double
    }

    private static let stars = [
        Star(x: 0.10, y: 0.14, diameter: 2, opacity: 0.5),
        Star(x: 0.82, y: 0.11, diameter: 2, opacity: 0.4),
        Star(x: 0.54, y: 0.18, diameter: 1.5, opacity: 0.6),
        Star(x: 0.23, y: 0.36, diameter: 1.5, opacity: 0.35),
        Star(x: 0.90, y: 0.31, diameter: 2, opacity: 0.45),
        Star(x: 0.06, y: 0.50, diameter: 1.5, opacity: 0.4),
        Star(x: 0.94, y: 0.56, diameter: 1.5, opacity: 0.5),
        Star(x: 0.36, y: 0.08, diameter: 1.5, opacity: 0.5),
        Star(x: 0.69, y: 0.45, diameter: 1.5, opacity: 0.3),
        Star(x: 0.15, y: 0.78, diameter: 1.5, opacity: 0.3),
        Star(x: 0.86, y: 0.84, diameter: 2, opacity: 0.35),
    ]
}

extension View {
    /// Fades the view in while it rises into place.
    func revealRising(isVisible: Bool, distance: CGFloat) -> some View {
        opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : distance)
    }
}

/// Keeps a reveal still when it fits, and flashes the scroll indicators when the actions scroll
/// off-screen, where the system supports it.
struct NightfallScrollBehavior: ViewModifier {
    let flashesIndicators: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicatorsFlash(trigger: flashesIndicators)
        } else if #available(iOS 16.4, *) {
            content.scrollBounceBehavior(.basedOnSize)
        } else {
            content
        }
    }
}
