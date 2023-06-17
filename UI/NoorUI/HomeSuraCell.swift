//
//  HomeSuraCell.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/28/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI
import UIx

public struct HomeSuraCell: View {
    public init(
        page: Int,
        localizedSuraNumber: String,
        maxLocalizedSuraNumber: String,
        localizedSura: String,
        arabicSuraName: String,
        subtitle: String
    ) {
        self.page = page
        self.localizedSuraNumber = localizedSuraNumber
        self.maxLocalizedSuraNumber = maxLocalizedSuraNumber
        self.localizedSura = localizedSura
        self.arabicSuraName = arabicSuraName
        self.subtitle = subtitle
    }

    let page: Int
    let localizedSuraNumber: String
    let maxLocalizedSuraNumber: String
    let localizedSura: String
    let arabicSuraName: String
    let subtitle: String

    public var body: some View {
        HStack {
            ZStack {
                Text(maxLocalizedSuraNumber)
                    .font(.headline)
                    .fontWeight(.light)
                    .hidden()

                Text(localizedSuraNumber)
                    .font(.headline)
                    .fontWeight(.light)
                    .foregroundColor(.secondaryLabel)
            }
            .padding(.trailing)

            SuraSubtitleTextView(localizedSura: localizedSura, arabicSuraName: arabicSuraName, subtitle: subtitle)
                .padding(.trailing)

            PageNumberListItemView(page: page)
        }
        .padding()
    }
}

struct HomeSuraCell_Previews: PreviewProvider {
    private static let suraName = String(UnicodeScalar(0xE907)!)
    static var previews: some View {
        Previewing.list {
            HomeSuraCell(
                page: 1,
                localizedSuraNumber: "1",
                maxLocalizedSuraNumber: "200",
                localizedSura: "Sura 1",
                arabicSuraName: suraName,
                subtitle: "Makki - 7 verses"
            )
            Divider()

            HomeSuraCell(
                page: 1,
                localizedSuraNumber: "1",
                maxLocalizedSuraNumber: "200",
                localizedSura: "Sura 1",
                arabicSuraName: suraName,
                subtitle: "Madani - 200 verses"
            )
            Divider()
        }
    }
}
