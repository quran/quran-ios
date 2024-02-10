//
//  QuranPageHeader.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import SwiftUI

public struct QuranPageHeader: View {
    private let quarterName: String
    private let suraNames: MultipartText

    public init(quarterName: String, suraNames: MultipartText) {
        self.quarterName = quarterName
        self.suraNames = suraNames
    }

    public var body: some View {
        HStack {
            Text(quarterName)
            Spacer()
            suraNames
                .view(ofSize: .footnote, alignment: .trailing)
        }
        .readableInsetsPadding([.top, .horizontal])
        .padding(.bottom, ContentDimension.interSpacing)
    }
}
