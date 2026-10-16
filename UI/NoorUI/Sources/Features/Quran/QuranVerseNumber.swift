//
//  QuranVerseNumber.swift
//
//
//  Created by Mohamed Afifi on 2026-10-08.
//

import Localization
import QuranAnnotations
import QuranKit
import SwiftUI
import UIx

public struct QuranVerseNumber: View {
    @ScaledMetric private var topPadding = 10
    @ScaledMetric(relativeTo: .footnote) private var horizontalPadding = 12
    @ScaledMetric(relativeTo: .footnote) private var verticalPadding = 6
    @ScaledMetric(relativeTo: .footnote) private var spacing = 8
    @ScaledMetric(relativeTo: .footnote) private var dividerHeight = 13

    let verse: AyahNumber

    #if QURAN_SYNC
    private let indicators: Set<AyahIndicator>
    private let onTapped: ((CGPoint) -> Void)?
    @State private var capsuleFrame: CGRect = .zero

    /// A `nil` `onTapped` shows the capsule as a plain label.
    public init(verse: AyahNumber, indicators: Set<AyahIndicator>, onTapped: ((CGPoint) -> Void)?) {
        self.verse = verse
        self.indicators = indicators
        self.onTapped = onTapped
    }
    #else
    public init(verse: AyahNumber) {
        self.verse = verse
    }
    #endif

    public var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, topPadding)
            .readableInsetsPadding(.horizontal)
    }

    @ViewBuilder
    private var content: some View {
        #if QURAN_SYNC
        if let onTapped {
            Button {
                onTapped(CGPoint(x: capsuleFrame.midX, y: capsuleFrame.midY))
            } label: {
                capsule
                    .onGlobalFrameChanged { capsuleFrame = $0 }
                    .minimumTouchTarget()
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("translation-ayah-number-\(verse.sura.suraNumber)-\(verse.ayah)")
        } else {
            capsule
        }
        #else
        capsule
        #endif
    }

    private var capsule: some View {
        HStack(spacing: spacing) {
            Text(lFormat("translation.text.ayah-number", verse.sura.suraNumber, verse.ayah))
            #if QURAN_SYNC
            if !indicators.isEmpty {
                Divider()
                    .frame(height: dividerHeight)
                ForEach(indicators.ordered) { indicator in
                    AyahIndicatorIcon(indicator: indicator)
                }
            }
            #endif
        }
        .font(.footnote)
        .fixedSize()
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .themedSecondaryForeground()
        .themedSecondaryBackground()
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }
}

#if QURAN_SYNC
#Preview("Verse number and indicators") {
    VStack(spacing: 0) {
        ForEach([Set<AyahIndicator>(), [.note], [.readingBookmark(.teal), .readingBookmark(.orange), .collection, .note]], id: \.self) { indicators in
            QuranVerseNumber(
                verse: Quran.hafsMadani1405.suras[1].verses[7],
                indicators: indicators,
                onTapped: { _ in }
            )
        }
    }
    .padding()
    .themedBackground()
}
#else
#Preview("Verse number") {
    QuranVerseNumber(verse: Quran.hafsMadani1405.suras[1].verses[7])
        .padding()
        .themedBackground()
}
#endif
