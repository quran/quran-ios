//
//  AppIconRevealStyle.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import SwiftUI
import UIKit
import UIx

/// The reveal's fixed navy and gold, independent of the app accent and appearance.
enum AppIconRevealPalette {
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

    // MARK: Private

    private static func color(_ rgb: Int) -> Color {
        Color(UIColor(rgb: rgb))
    }
}

/// The reveal's timeline, in seconds after the view appears.
enum AppIconRevealTimeline {
    struct Beat {
        let start: TimeInterval
        let duration: TimeInterval

        var end: TimeInterval {
            start + duration
        }
    }

    static let nightRise = Beat(start: 0.45, duration: 1.5)
    static let horizonGlowFade = Beat(start: 1.35, duration: 0.6)
    static let tileFade = Beat(start: 0.9, duration: 0.8)
    static let previousIconFade = Beat(start: 0.95, duration: 0.9)
    static let glyphWrite = Beat(start: 1.2, duration: 1.3)
    static let penIn = Beat(start: 1.2, duration: 0.25)
    static let penOut = Beat(start: 2.2, duration: 0.3)
    static let iconGlow = Beat(start: 2.3, duration: 1.2)
    static let sheen = Beat(start: 2.75, duration: 0.9)
    static let newIcon = Beat(start: 3.1, duration: 0.5)
    static let lift = Beat(start: 3.2, duration: 0.9)
    static let title = Beat(start: 3.55, duration: 0.7)
    static let body = Beat(start: 3.7, duration: 0.7)
    static let actions = Beat(start: 3.95, duration: 0.7)
    /// Reduce Motion and VoiceOver get a simple crossfade into the final layout.
    static let crossfade = Beat(start: 0.3, duration: 0.6)

    /// When night reaches the top of the screen and the status bar turns light.
    static let nightfall: TimeInterval = 1.6
}

/// Where the reveal places the icon and the copy.
///
/// The icon scrolls with the copy, so text never slides under it. At accessibility text sizes,
/// the icon lifts higher and smaller and the actions scroll with the copy.
struct AppIconRevealLayout {
    // MARK: Internal

    /// The icon art, drawn at a fixed size so the `app-glyph` template lines up with the new icon.
    static let iconLength: CGFloat = 148
    static let contentMaxWidth: CGFloat = 440

    let size: CGSize
    let insets: EdgeInsets
    let isAccessibilitySize: Bool
    let copyTopSpacing: CGFloat

    var scrollsActions: Bool {
        isAccessibilitySize
    }

    /// Where the icon rests before it lifts, in the scrolling content.
    var restingCenter: CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2)
    }

    var liftedScale: CGFloat {
        isAccessibilitySize ? 0.6 : 0.9
    }

    var liftOffset: CGFloat {
        liftedCenterY - restingCenter.y
    }

    var copyTop: CGFloat {
        liftedCenterY + Self.iconLength * liftedScale / 2 + copyTopSpacing
    }

    // MARK: Private

    private static let lift: CGFloat = 122
    private static let accessibilityIconTopSpacing: CGFloat = 24

    private var liftedCenterY: CGFloat {
        if isAccessibilitySize {
            insets.top + Self.accessibilityIconTopSpacing + Self.iconLength * liftedScale / 2
        } else {
            size.height / 2 - Self.lift
        }
    }
}

extension View {
    /// Fades the view in while it rises into place.
    func revealRising(isVisible: Bool, distance: CGFloat) -> some View {
        opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : distance)
    }
}
