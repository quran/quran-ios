//
//  QuranArabicText.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import Localization
import NoorFont
import QuranAnnotations
import QuranKit
import QuranText
import SwiftUI
import UIx

public struct QuranArabicText: View {
    @ScaledMetric var bottomPadding = 5
    @ScaledMetric var topPadding = 10
    @ScaledMetric(relativeTo: .footnote) private var ayahNumberHorizontalPadding = 12
    @ScaledMetric(relativeTo: .footnote) private var ayahNumberVerticalPadding = 6
    @ScaledMetric(relativeTo: .footnote) private var ayahNumberSpacing = 8
    @ScaledMetric(relativeTo: .footnote) private var annotationSize = 13

    let verse: AyahNumber
    let text: QuranText
    let quranFont: QuranFont
    let fontSize: FontSize

    #if QURAN_SYNC
    private let annotations: Set<AyahAnnotation>
    private let onAyahNumberTapped: ((CGPoint) -> Void)?
    @State private var capsuleFrame: CGRect = .zero
    @ScaledMetric private var minimumTargetSize = 44.0

    public init(verse: AyahNumber, text: QuranText, quranFont: QuranFont, fontSize: FontSize, annotations: Set<AyahAnnotation>, onAyahNumberTapped: ((CGPoint) -> Void)? = nil) {
        self.verse = verse
        self.text = text
        self.quranFont = quranFont
        self.fontSize = fontSize
        self.annotations = annotations
        self.onAyahNumberTapped = onAyahNumberTapped
    }
    #else
    public init(verse: AyahNumber, text: QuranText, quranFont: QuranFont, fontSize: FontSize) {
        self.verse = verse
        self.text = text
        self.quranFont = quranFont
        self.fontSize = fontSize
    }
    #endif

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ayahNumber

            QuranTextView(
                text,
                quranFont: quranFont,
                fontOverrides: ayahMarkerFontOverrides
            )
            .dynamicTypeSize(fontSize.dynamicTypeSize)
            .textAlignment(follows: .rightToLeft)
        }
        .padding(.bottom, bottomPadding)
        .padding(.top, topPadding)
        .readableInsetsPadding(.horizontal)
    }

    @ViewBuilder
    private var ayahNumber: some View {
        #if QURAN_SYNC
        if let onAyahNumberTapped {
            Button {
                onAyahNumberTapped(CGPoint(x: capsuleFrame.midX, y: capsuleFrame.midY))
            } label: {
                capsule
                    .onGlobalFrameChanged { capsuleFrame = $0 }
                    .frame(minWidth: minimumTargetSize, minHeight: minimumTargetSize)
                    .contentShape(Rectangle())
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
        HStack(spacing: ayahNumberSpacing) {
            Text(lFormat("translation.text.ayah-number", verse.sura.suraNumber, verse.ayah))
            #if QURAN_SYNC
            if !annotations.isEmpty {
                Divider()
                    .frame(height: annotationSize)
                ForEach(annotations.ordered) { annotation in
                    AyahAnnotationIcon(annotation: annotation, size: annotationSize)
                }
            }
            #endif
        }
        .font(.footnote)
        .fixedSize()
        .padding(.horizontal, ayahNumberHorizontalPadding)
        .padding(.vertical, ayahNumberVerticalPadding)
        .themedSecondaryForeground()
        .themedSecondaryBackground()
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }

    var ayahMarkerFontOverrides: [QuranTextFontOverride] {
        guard quranFont == .indoPak else {
            return []
        }
        let marker = NumberFormatter.arabicNumberFormatter.format(verse.ayah)
        guard let range = text.text.range(of: marker, options: .backwards),
              range.upperBound == text.text.endIndex
        else {
            return []
        }
        return [QuranTextFontOverride(range: range, quranFont: .uthmanicHafs)]
    }
}

#if QURAN_SYNC
#Preview("Ayah number and annotations") {
    VStack(alignment: .leading) {
        ForEach([Set<AyahAnnotation>(), [.note], [.readingBookmark(.coral), .readingBookmark(.teal), .collection, .note]], id: \.self) { annotations in
            QuranArabicText(
                verse: Quran.hafsMadani1405.suras[1].verses[7],
                text: QuranText(""),
                quranFont: .uthmanicHafs,
                fontSize: .medium,
                annotations: annotations
            )
        }
    }
    .padding()
    .themedBackground()
}
#endif
