//
//  HighlightPaletteIcon.swift
//
//  Created by Ahmed Nabil on 2026-05-10.
//

import QuranAnnotations
import SwiftUI

public struct HighlightPaletteIcon: View {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public var body: some View {
        ZStack {
            colorCircle(.purple)
                .offset(x: purpleOffset)
            colorCircle(.blue)
                .offset(x: blueOffset)
            colorCircle(.green)
        }
        .compositingGroup()
        .shadow(color: Color.tertiarySystemGroupedBackground, radius: radius)
        .padding(.trailing, trailingPadding)
    }

    // MARK: Private

    @ScaledMetric private var trailingPadding = ContentDimension.interSpacing
    @ScaledMetric private var purpleOffset = ContentDimension.interSpacing
    @ScaledMetric private var blueOffset = ContentDimension.interSpacing / 2
    @ScaledMetric private var minLength = 20.0
    @ScaledMetric private var radius = 1.0

    private func colorCircle(_ color: HighlightColor) -> some View {
        ColoredCircle(color: color.color, selected: false, minLength: minLength)
    }
}
