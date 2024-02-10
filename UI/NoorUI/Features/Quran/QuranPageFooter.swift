//
//  QuranPageFooter.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import SwiftUI

public struct QuranPageFooter: View {
    let page: String

    public init(page: String) {
        self.page = page
    }

    public var body: some View {
        HStack {
            Spacer()
            Text(page)
            Spacer()
        }
        .padding(.top, ContentDimension.interSpacing)
        .readableInsetsPadding([.bottom, .horizontal])
    }
}
