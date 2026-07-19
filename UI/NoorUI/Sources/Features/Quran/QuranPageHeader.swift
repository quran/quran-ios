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
    private let readableInsetEdges: Edge.Set

    public init(
        quarterName: String,
        suraNames: MultipartText,
        readableInsetEdges: Edge.Set = [.top, .horizontal]
    ) {
        self.quarterName = quarterName
        self.suraNames = suraNames
        self.readableInsetEdges = readableInsetEdges
    }

    public var body: some View {
        HStack {
            Text(quarterName)
            Spacer()
            suraNames
                // TODO: Should get footnote from environment.
                .view(ofSize: .footnote, alignment: .trailing)
        }
        .readableInsetsPadding(readableInsetEdges)
        .padding(.bottom, ContentDimension.interSpacing)
    }
}
