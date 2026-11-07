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

    @Environment(\.compactsPageChrome) private var compactsPageChrome
    @Environment(\.windowSafeAreaInsets) private var windowSafeAreaInsets

    public init(page: String, readableInsetEdges: Edge.Set = [.bottom, .horizontal]) {
        self.page = page
        self.readableInsetEdges = readableInsetEdges
    }

    public var body: some View {
        if compactsPageChrome, readableInsetEdges.contains(.bottom) {
            pageNumber
                .padding(.top, ContentDimension.CompactPageChrome.spacing)
                .readableInsetsPadding(readableInsetEdges.subtracting(.bottom))
                .padding(.bottom, ContentDimension.CompactPageChrome.footerBottom(safeAreaBottom: windowSafeAreaInsets.bottom))
        } else {
            pageNumber
                .padding(.top, ContentDimension.interSpacing)
                .readableInsetsPadding(readableInsetEdges)
        }
    }

    private var pageNumber: some View {
        HStack {
            Spacer()
            Text(page)
            Spacer()
        }
    }
}
