//
//  HomeQuarterCell.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/28/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import SwiftUI
import UIx

public struct HomeQuarterCell: View {
    // MARK: Lifecycle

    public init(
        page: Int,
        maxPage: Int,
        text: String,
        localizedVerse: String,
        arabicSuraName: String,
        localizedQuarter: String,
        maxLocalizedQuarter: String
    ) {
        self.page = page
        self.maxPage = maxPage
        self.text = text
        self.localizedVerse = localizedVerse
        self.arabicSuraName = arabicSuraName
        self.localizedQuarter = localizedQuarter
        self.maxLocalizedQuarter = maxLocalizedQuarter
    }

    // MARK: Public

    public var body: some View {
        HStack {
            ZStack {
                Text(localizedQuarter)
                    .font(.subheadline)
                Text(maxLocalizedQuarter)
                    .font(.subheadline)
                    .hidden()
            }
            .padding(.trailing)

            VStack {
                HStack {
                    Text(text)
                        .font(.quran(ofSize: .small))
                        .lineLimit(1)
                    Spacer()
                }

                HStack {
                    SuraTextView(style: .footnote, title: localizedVerse, arabicSuraName: arabicSuraName, withSpacer: false)
                        .foregroundColor(.secondaryLabel)
                    Spacer()
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
            .padding(.trailing)

            ZStack {
                PageNumberListItemView(page: page)
                PageNumberListItemView(page: maxPage)
                    .hidden()
            }
        }
        .padding()
    }

    // MARK: Internal

    let page: Int
    let maxPage: Int
    let text: String
    let localizedVerse: String
    let arabicSuraName: String
    let localizedQuarter: String
    let maxLocalizedQuarter: String
}

// swiftlint:disable line_length
struct HomeQuarterCell_Previews: PreviewProvider {
    // MARK: Internal

    static var previews: some View {
        Previewing.list {
            HomeQuarterCell(
                page: 1,
                maxPage: 600,
                text: " عَمَّ يَتَسَاءَلُونَ",
                localizedVerse: "Sura 30, ayah: 22",
                arabicSuraName: suraName,
                localizedQuarter: "Hizb 1",
                maxLocalizedQuarter: "¾ Hizb 59"
            )
            Divider()

            HomeQuarterCell(
                page: 599,
                maxPage: 600,
                text: " تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْك تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْك تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْك تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْك تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْك تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْك تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ",
                localizedVerse: "Sura 30, ayah: 22",
                arabicSuraName: suraName,
                localizedQuarter: "¼ Hizb 3",
                maxLocalizedQuarter: "¾ Hizb 59"
            )
            Divider()

            HomeQuarterCell(
                page: 1,
                maxPage: 20,
                text: " عَمَّ يَتَسَاءَلُونَ",
                localizedVerse: "Sura 30, ayah: 22",
                arabicSuraName: suraName,
                localizedQuarter: "½ Hizb 117",
                maxLocalizedQuarter: "¾ Hizb 59"
            )
            Divider()

            HomeQuarterCell(
                page: 1,
                maxPage: 600,
                text: " تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ",
                localizedVerse: "Sura 30, ayah: 22",
                arabicSuraName: suraName,
                localizedQuarter: "¾ Hizb 117",
                maxLocalizedQuarter: "¾ Hizb 59"
            )
            Divider()
        }
    }

    // MARK: Private

    private static let suraName = String(UnicodeScalar(0xE907)!)
}

// swiftlint:enable line_length
