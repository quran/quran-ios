//
//  QuranPageHeader.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import QuranKit
import SwiftUI

public struct QuranPageHeader: View {
    // MARK: Lifecycle

    public init(
        quarterName: String,
        suras: [Sura],
        readableInsetEdges: Edge.Set = [.top, .horizontal]
    ) {
        self.quarterName = quarterName
        self.suras = suras
        self.readableInsetEdges = readableInsetEdges
    }

    // MARK: Public

    public var body: some View {
        HStack {
            Text(quarterName)
            Spacer()
            // TODO: Should get footnote from environment.
            QuranPageHeaderSuraNames(suras: suras, size: .footnote)
        }
        .readableInsetsPadding(readableInsetEdges)
        .padding(.bottom, ContentDimension.interSpacing)
    }

    // MARK: Private

    private let quarterName: String
    private let suras: [Sura]
    private let readableInsetEdges: Edge.Set
}

/// The decorated sura names on one line, or the standard names when they don't fit.
struct QuranPageHeaderSuraNames: View {
    // MARK: Internal

    let suras: [Sura]
    let size: MultipartText.FontSize

    var body: some View {
        if #available(iOS 16.0, *) {
            ViewThatFits(in: .horizontal) {
                decoratedNames(suras)
                standardNames
            }
        } else {
            standardNames
        }
    }

    // MARK: Private

    /// A hidden decorated name keeps the decorated line height, so the page content doesn't resize between pages.
    private var standardNames: some View {
        ZStack(alignment: .trailing) {
            decoratedNames(Array(suras.prefix(1)))
                .frame(width: 0)
                .hidden()
                .accessibilityHidden(true)
            MultipartText("\(suras: suras)")
                .view(ofSize: size, alignment: .trailing)
        }
    }

    private func decoratedNames(_ suras: [Sura]) -> some View {
        MultipartText("\(suras: suras, nameStyle: .decorated)")
            .view(ofSize: size, alignment: .trailing, allowsWrapping: false)
    }
}
