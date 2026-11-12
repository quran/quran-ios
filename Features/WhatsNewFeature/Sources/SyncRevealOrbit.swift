//
//  SyncRevealOrbit.swift
//
//
//  Created by Mohamed Afifi on 2026-11-11.
//

import SwiftUI

/// The app icon at the center of a slowly turning gold ring, with the places that sync on it:
/// iPhone at the top, Quran.com on the left, and iPad on the right.
///
/// It's decorative: the copy beneath says the same thing, so VoiceOver skips it.
struct SyncRevealOrbit: View {
    // MARK: Internal

    /// The width and height the orbit takes at full size, nodes and labels included.
    static let size = CGSize(width: ringLength + 40, height: ringLength + nodeLength / 2 + 2)

    let icon: Image

    var body: some View {
        ZStack {
            ring
            centerIcon
            node(symbol: "iphone", label: "iPhone", angle: -90)
            node(symbol: "globe", label: "Quran.com", angle: 150)
            node(symbol: "ipad", label: "iPad", angle: 30)
        }
        .frame(width: Self.ringLength, height: Self.ringLength)
        .offset(y: Self.nodeLength / 4)
        .frame(width: Self.size.width, height: Self.size.height)
        // The nodes keep their places in every locale, like the artwork they are.
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }

    // MARK: Private

    private typealias Palette = NightfallPalette

    private static let ringLength: CGFloat = 300
    private static let nodeLength: CGFloat = 50
    private static let iconLength: CGFloat = 120
    private static let iconCornerRadius: CGFloat = 28
    private static let iconHaloWidth: CGFloat = 10
    /// One turn of the ring, in seconds.
    private static let turnDuration: TimeInterval = 40

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var ring: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
            Circle()
                .strokeBorder(
                    Palette.gold.opacity(0.45),
                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 5])
                )
                .rotationEffect(reduceMotion ? .zero : rotation(at: context.date))
        }
    }

    private var centerIcon: some View {
        let shape = RoundedRectangle(cornerRadius: Self.iconCornerRadius, style: .continuous)
        return icon
            .resizable()
            .scaledToFit()
            .frame(width: Self.iconLength, height: Self.iconLength)
            // The icon's default look, whatever the app's appearance setting.
            .environment(\.colorScheme, .light)
            .clipShape(shape)
            .background(
                RoundedRectangle(
                    cornerRadius: Self.iconCornerRadius + Self.iconHaloWidth,
                    style: .continuous
                )
                .fill(Palette.gold.opacity(0.12))
                .padding(-Self.iconHaloWidth)
            )
            .shadow(color: Palette.gold.opacity(0.35), radius: 30)
    }

    private func node(symbol: String, label: String, angle: Double) -> some View {
        let radians = angle * .pi / 180
        let radius = Self.ringLength / 2
        return VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Palette.gold)
                .frame(width: Self.nodeLength, height: Self.nodeLength)
                .background(Circle().fill(Palette.node))
                .overlay(Circle().strokeBorder(Palette.gold.opacity(0.6), lineWidth: 1))

            Text(verbatim: label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.7))
                .lineLimit(1)
                .fixedSize()
                // Grows with the text size, short of crowding the ring.
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
        }
        // Centers the node's circle, not the circle and its label, on the ring.
        .alignmentGuide(VerticalAlignment.center) { $0[.top] + Self.nodeLength / 2 }
        .offset(x: radius * cos(radians), y: radius * sin(radians))
    }

    private func rotation(at date: Date) -> Angle {
        let progress = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: Self.turnDuration) / Self.turnDuration
        return .degrees(progress * 360)
    }
}

#Preview {
    SyncRevealOrbit(icon: Image(systemName: "app.fill"))
        .padding()
        .background(NightfallPalette.night)
}
