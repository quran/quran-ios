//
//  AyahNumberView.swift
//

import Localization
import QuranKit
import SwiftUI

public struct AyahNumberView: View {
    private let number: Int
    private let palette: QuranPageChromePalette

    public init(number: Int, palette: QuranPageChromePalette) {
        self.number = number
        self.palette = palette
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(palette.markerFill)
                .padding(5)

            ayahRing
                .foregroundColor(palette.markerRing)

            ayahText
                .foregroundColor(palette.markerText)
        }
    }

    private var ayahRing: some View {
        NoorImage.ayahEnd.image
            .renderingMode(.template)
            .resizable()
            .padding(.horizontal, 1)
            .aspectRatio(contentMode: .fit)
    }

    private var ayahText: some View {
        Text(NumberFormatter.arabicNumberFormatter.format(number))
            .font(.largeTitle)
            .minimumScaleFactor(0.03)
            .padding(3)
    }
}

#Preview {
    let palette = QuranPageChromeStyle.green.palette(for: .light)
    List {
        AyahNumberView(number: 1, palette: palette)
            .frame(height: 40)
        AyahNumberView(number: 2, palette: palette)
            .frame(height: 40)

        AyahNumberView(number: 100, palette: palette)
            .frame(height: 40)

        AyahNumberView(number: 999, palette: palette)
            .frame(height: 40)

        #if QURAN_SYNC
        let ayah = Quran.hafsMadani1405.suras[1].verses[99]
        AyahNumberView(number: 100, palette: palette)
            .frame(height: 40)
            .background {
                GeometryReader { geometry in
                    AyahReadingBookmarkUnderlines(
                        markers: [.init(ayah: ayah, frame: CGRect(origin: .zero, size: geometry.size))],
                        bookmarks: [ayah: [.teal, .orange]]
                    )
                }
            }
            .padding(.bottom, 20)
        #endif
    }
    .themedBackground()
    .environment(\.themeStyle, .paper)
}
