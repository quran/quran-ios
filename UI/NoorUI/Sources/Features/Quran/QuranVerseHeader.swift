//
//  QuranVerseHeader.swift
//
//
//  Created by Mohamed Afifi on 2026-10-09.
//

import NoorFont
import QuranAnnotations
import QuranKit
import QuranText
import SwiftUI
import UIx

/// The first row of a verse in translation mode when the Arabic text is shown: its verse-number capsule and Quran text.
///
/// The capsule shares the Quran text's line when the text fits on one line next to it,
/// and sits above the text otherwise.
public struct QuranVerseHeader: View {
    // MARK: Lifecycle

    public init(verseNumber: QuranVerseNumber, arabicText: QuranArabicText) {
        self.verseNumber = verseNumber
        self.arabicText = arabicText
    }

    // MARK: Public

    public var body: some View {
        content
            .padding(.top, topPadding)
            .readableInsetsPadding(.horizontal)
    }

    // MARK: Private

    @ScaledMetric private var topPadding = QuranTranslationSpacing.verseTop
    @ScaledMetric private var spacing = 12

    private let verseNumber: QuranVerseNumber
    private let arabicText: QuranArabicText

    @ViewBuilder
    private var content: some View {
        if #available(iOS 16.0, *) {
            ViewThatFits(in: .horizontal) {
                sharedLine
                stacked
            }
        } else {
            stacked
        }
    }

    private var sharedLine: some View {
        HStack(spacing: spacing) {
            verseNumber
            arabicText
                .fixedSize(horizontal: true, vertical: false)
                .textAlignment(follows: .rightToLeft)
        }
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: 0) {
            verseNumber
            arabicText
                .textAlignment(follows: .rightToLeft)
        }
    }
}

#Preview("Verse header") {
    let verses = Quran.hafsMadani1405.suras[111].verses
    return VStack(spacing: 0) {
        QuranVerseHeader(
            verseNumber: previewVerseNumber(verses[0]),
            arabicText: QuranArabicText(verse: verses[0], text: "قُلۡ هُوَ ٱللَّهُ أَحَدٌ ١", quranFont: .uthmanicHafs, fontSize: .medium)
        )
        QuranVerseHeader(
            verseNumber: previewVerseNumber(verses[1]),
            arabicText: QuranArabicText(
                verse: verses[1],
                text: "ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ٱلۡقَيُّومُۚ لَا تَأۡخُذُهُۥ سِنَةٞ وَلَا نَوۡمٞۚ لَّهُۥ مَا فِي ٱلسَّمَٰوَٰتِ ٢",
                quranFont: .uthmanicHafs,
                fontSize: .medium
            )
        )
    }
    .populateReadableInsets()
    .themedBackground()
    .onAppear { FontName.registerFonts() }
}

private func previewVerseNumber(_ verse: AyahNumber) -> QuranVerseNumber {
    #if QURAN_SYNC
    QuranVerseNumber(verse: verse, annotations: [.note], onTapped: { _ in })
    #else
    QuranVerseNumber(verse: verse)
    #endif
}
