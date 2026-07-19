//
//  QuranPageFooter.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import SwiftUI

public struct QuranPageFooter: View {
    let page: String
    let readableInsetEdges: Edge.Set

    public init(page: String, readableInsetEdges: Edge.Set = [.bottom, .horizontal]) {
        self.page = page
        self.readableInsetEdges = readableInsetEdges
    }

    public var body: some View {
        HStack {
            Spacer()
            Text(page)
            Spacer()
        }
        .padding(.top, ContentDimension.interSpacing)
        .readableInsetsPadding(readableInsetEdges)
    }
}
