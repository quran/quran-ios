//
//  SuraTextView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/27/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import SwiftUI
import UIx

struct SuraTextView: View {
    enum Style {
        case subheading
        case footnote
        case caption

        var font: Font {
            switch self {
            case .subheading:
                return .subheadline
            case .footnote:
                return .footnote
            case .caption:
                return .caption
            }
        }

        var suraNameSize: CGFloat {
            switch self {
            case .subheading:
                return 19
            case .footnote:
                return 18
            case .caption:
                return 17
            }
        }
    }

    let style: Style
    let withSpacer: Bool

    let title: String
    let arabicSuraName: String

    init(style: Style = .subheading, title: String, arabicSuraName: String, withSpacer: Bool = true) {
        self.style = style
        self.title = title
        self.arabicSuraName = arabicSuraName
        self.withSpacer = withSpacer
    }

    var body: some View {
        HStack {
            Text(title)
                .font(style.font)
            if NSLocale.preferredLanguages.first != "ar" {
                Text(arabicSuraName)
                    .padding(.top, 5)
                    .frame(alignment: .center)
                    .font(.custom(.suraNames, size: style.suraNameSize))
            }
            if withSpacer {
                Spacer()
            }
        }
    }
}

@available(iOS 13.0, *)
struct SuraTextView_Previews: PreviewProvider {
    private static let suraName = String(UnicodeScalar(0xE907)!)
    static var previews: some View {
        Previewing.list {
            SuraTextView(title: "Sura 1", arabicSuraName: suraName)
                .padding()
            Divider()

            SuraTextView(title: "Sura 1, Verse 2", arabicSuraName: suraName)
                .padding()
            Divider()

            SuraTextView(title: "Sura 1", arabicSuraName: suraName, withSpacer: false)
                .padding()
            Divider()

            SuraTextView(style: .footnote, title: "Sura 1", arabicSuraName: suraName)
                .foregroundColor(.secondaryLabel)
                .padding()
            Divider()
        }
    }
}
