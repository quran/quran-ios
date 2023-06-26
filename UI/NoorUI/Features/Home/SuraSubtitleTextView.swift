//
//  SuraSubtitleTextView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/28/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI
import UIx

struct SuraSubtitleTextView: View {
    let localizedSura: String
    let arabicSuraName: String
    let subtitle: String

    var body: some View {
        VStack {
            SuraTextView(title: localizedSura, arabicSuraName: arabicSuraName)
            HStack {
                Text(subtitle)
                    .font(.footnote)
                    .fontWeight(.light)
                    .foregroundColor(.secondaryLabel)
                Spacer()
            }
        }
    }
}

struct SuraSubtitleTextView_Previews: PreviewProvider {
    // MARK: Internal

    static var previews: some View {
        Previewing.list {
            SuraSubtitleTextView(
                localizedSura: "Sura 1",
                arabicSuraName: suraName,
                subtitle: "Makki - 7 verses"
            )
            .padding()
            Divider()
        }
    }

    // MARK: Private

    private static let suraName = String(UnicodeScalar(0xE907)!)
}
