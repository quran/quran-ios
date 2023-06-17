//
//  PageBookmarkCell.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/27/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI
import UIx

public struct PageBookmarkCell: View {
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
                BookmarkDateSinceView(since: createdSince)
            }

            PageNumberListItemView(page: page)
        }
        .padding()
    }
}

struct PageBookmarkCell_Previews: PreviewProvider {
    private static let suraName = String(UnicodeScalar(0xE907)!)
    static var previews: some View {
        Previewing.list {
            PageBookmarkCell(
                page: 1,
                localizedSura: "Sura 1",
                arabicSuraName: suraName,
                createdSince: "Just now"
            )
            Divider()

            PageBookmarkCell(
                page: 44,
                localizedSura: "Sura 1",
                arabicSuraName: suraName,
                createdSince: "Just now"
            )
            Divider()
        }
    }
}
