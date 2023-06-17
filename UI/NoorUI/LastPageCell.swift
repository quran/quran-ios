//
//  LastPageCell.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/28/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI
import UIx

public struct LastPageCell: View {
    public init(
        page: Int,
        localizedSura: String,
        arabicSuraName: String,
        createdSince: String
    ) {
        self.page = page
        self.localizedSura = localizedSura
        self.arabicSuraName = arabicSuraName
        self.createdSince = createdSince
    }

    let page: Int
    let localizedSura: String
    let arabicSuraName: String
    let createdSince: String

    public var body: some View {
        HStack {
            VStack {
                SuraTextView(title: localizedSura, arabicSuraName: arabicSuraName)
                RecentDateSinceView(since: createdSince)
            }

            PageNumberListItemView(page: page)
        }
        .padding()
    }
}

struct LastPageCell_Previews: PreviewProvider {
    private static let suraName = String(UnicodeScalar(0xE907)!)
    static var previews: some View {
        Previewing.list {
            LastPageCell(
                page: 1,
                localizedSura: "Sura 1",
                arabicSuraName: suraName,
                createdSince: "Just now"
            )
            Divider()

            LastPageCell(
                page: 44,
                localizedSura: "Sura 2",
                arabicSuraName: suraName,
                createdSince: "Just now"
            )
            Divider()
        }
    }
}
