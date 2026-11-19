//
//  ImageDecorationsView.swift
//

import SwiftUI
import UIx

struct ImageDecorationsView: View {
    let layout: ImageDecorationsLayout
    let chromeStyle: QuranPageChromeStyle

    var body: some View {
        ZStack(alignment: .topLeading) {
            highlights
            suraHeaders
            ayahNumbers
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: Private

    @Environment(\.quranPageColorScheme) private var quranPageColorScheme
    @Environment(\.themeColors) private var themeColors

    private var chromePalette: QuranPageChromePalette {
        chromeStyle.palette(for: quranPageColorScheme, text: themeColors.text)
    }

    private var highlights: some View {
        ZStack(alignment: .topLeading) {
            ForEach(layout.verseHighlights) { placement in
                QuranHighlightShape(lineRects: placement.lineRects)
                    .fill(placement.color)
            }
            if let word = layout.wordHighlight {
                QuranHighlightShape.word(word.frame)
                    .fill(word.color)
            }
        }
    }

    private var suraHeaders: some View {
        ForEach(layout.suraHeaders) { placement in
            SuraHeaderView(tint: chromePalette.header)
                .placed(in: placement.frame)
        }
    }

    private var ayahNumbers: some View {
        ForEach(layout.drawnAyahMarkers, id: \.ayah) { placement in
            AyahNumberView(number: placement.ayah.ayah, palette: chromePalette)
                .placed(in: placement.frame)
        }
    }
}
