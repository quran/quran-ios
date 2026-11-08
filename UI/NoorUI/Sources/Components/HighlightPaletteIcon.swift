//
//  HighlightPaletteIcon.swift
//
//  Created by Ahmed Nabil on 2026-05-10.
//

import QuranAnnotations
import SwiftUI

/// Overlapping highlight-color circles. The first color sits on top at the leading edge,
/// and each later one tucks behind it toward the trailing edge.
public struct HighlightPaletteIcon: View {
    // MARK: Lifecycle

    /// - Parameter size: The diameter of each circle, scaled with Dynamic Type.
    public init(colors: [HighlightColor] = [.green, .blue, .purple], size: CGFloat = 20) {
        self.colors = colors
        _size = ScaledMetric(wrappedValue: size)
    }

    // MARK: Public

    public var body: some View {
        // Negative spacing overlaps the circles while keeping their full width in the layout,
        // so the icon centers and mirrors in right-to-left layouts.
        HStack(spacing: size * Self.peekRatio - size) {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                ColoredCircle(color: color.color, selected: false, minLength: size)
                    .zIndex(Double(colors.count - index))
            }
        }
        .compositingGroup()
        .shadow(color: Color.tertiarySystemGroupedBackground, radius: radius)
    }

    // MARK: Private

    /// How much of each circle peeks out from behind the one before it.
    private static let peekRatio = 0.2

    @ScaledMetric private var size: CGFloat
    @ScaledMetric private var radius = 1.0

    private let colors: [HighlightColor]
}

#Preview {
    VStack(spacing: 24) {
        HighlightPaletteIcon()
        HighlightPaletteIcon(colors: [.yellow, .green, .blue, .pink], size: 24)
        HighlightPaletteIcon(colors: [.yellow], size: 24)
        HighlightPaletteIcon(colors: [.yellow, .green, .blue], size: 24)
            .environment(\.layoutDirection, .rightToLeft)
    }
    .padding()
    .background(Color.secondarySystemGroupedBackground)
}
