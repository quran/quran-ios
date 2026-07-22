//
//  QuranSuraName.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import QuranKit
import QuranText
import SwiftUI

public struct QuranSuraName: View {
    @ScaledMetric var bottomPadding = 5
    @ScaledMetric var topPadding = 10

    let sura: Sura
    let besmAllah: String
    let besmAllahFontSize: FontSize

    public init(sura: Sura, besmAllah: String, besmAllahFontSize: FontSize) {
        self.sura = sura
        self.besmAllah = besmAllah
        self.besmAllahFontSize = besmAllahFontSize
    }

    public var body: some View {
        VStack {
            NoorImage.suraHeader.image.resizable()
                .aspectRatio(contentMode: .fit)
                .overlay {
                    let name: MultipartText = "\(sura: sura)"
                    name.view(ofSize: .title3, alignment: .center, allowsWrapping: false)
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                }
            Text(besmAllah)
                .font(.quran())
                .dynamicTypeSize(besmAllahFontSize.dynamicTypeSize)
        }
        .padding(.bottom, bottomPadding)
        .padding(.top, topPadding)
        .readableInsetsPadding(.horizontal)
    }
}
