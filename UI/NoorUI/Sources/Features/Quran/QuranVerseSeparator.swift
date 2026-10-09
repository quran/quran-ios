//
//  QuranVerseSeparator.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import SwiftUI

/// A hairline between two verses in translation mode, inset to the readable text column.
public struct QuranVerseSeparator: View {
    @Environment(\.themeColors) private var themeColors
    @Environment(\.displayScale) private var displayScale
    @ScaledMetric private var topPadding = QuranTranslationSpacing.separatorTop

    public init() { }

    public var body: some View {
        Rectangle()
            .fill(themeColors.pageSeparatorLine)
            .frame(height: 1 / displayScale)
            .padding(.top, topPadding)
            .readableInsetsPadding(.horizontal)
    }
}

#Preview {
    VStack {
        QuranVerseSeparator()
    }
    .populateReadableInsets()
    .environment(\.themeStyle, .original)
}
