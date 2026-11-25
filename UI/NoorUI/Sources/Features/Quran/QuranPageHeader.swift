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
        textRow
            .readableInsetsPadding(readableInsetEdges)
            .padding(.bottom, ContentDimension.interSpacing)
    }

    // MARK: Private

    private let quarterName: String
    private let suras: [Sura]
    private let readableInsetEdges: Edge.Set
    @Environment(\.quranPageTextInsets) private var textInsets

    private var suraNames: QuranPageHeaderSuraNames {
        // TODO: Should get footnote from environment.
        QuranPageHeaderSuraNames(suras: suras, size: .footnote)
    }

    /// Inset decorated names, then inset standard names, then the full-width header.
    @ViewBuilder private var textRow: some View {
        if #available(iOS 16.0, *), textInsets != EdgeInsets() {
            // The full-width row sizes the header, since the insets follow the image, which follows the header's size.
            row(suraNames)
                .hidden()
                .accessibilityHidden(true)
                .overlay {
                    // Squeezed names drop their separators.
                    ViewThatFits(in: .horizontal) {
                        row(suraNames.decoratedNames.fixedSize(horizontal: true, vertical: false)).padding(textInsets)
                        row(suraNames.standardNames.fixedSize(horizontal: true, vertical: false)).padding(textInsets)
                        row(suraNames)
                    }
                }
        } else {
            row(suraNames)
        }
    }

    /// The quarter name lines up with the middle of the sura names: their text, or their calligraphy.
    private func row(_ suraNames: some View) -> some View {
        HStack(alignment: .decoratedSuraNameCenter) {
            Text(quarterName)
            Spacer()
            suraNames
        }
    }
}

extension EnvironmentValues {
    /// The page's text insets. The header applies them to its text row only, so attached views like ribbons
    /// keep its full width.
    var quranPageTextInsets: EdgeInsets {
        get { self[QuranPageTextInsetsKey.self] }
        set { self[QuranPageTextInsetsKey.self] = newValue }
    }
}

private struct QuranPageTextInsetsKey: EnvironmentKey {
    static let defaultValue = EdgeInsets()
}

/// The decorated sura names on one line, or the standard names when they don't fit.
struct QuranPageHeaderSuraNames: View {
    // MARK: Internal

    let suras: [Sura]
    let size: MultipartText.FontSize

    var body: some View {
        if #available(iOS 16.0, *) {
            ViewThatFits(in: .horizontal) {
                decoratedNames
                standardNames
            }
        } else {
            standardNames
        }
    }

    var decoratedNames: some View {
        decoratedNamesLine(suras)
    }

    /// A hidden decorated name keeps the decorated line height, so the page content doesn't resize between pages.
    var standardNames: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .decoratedSuraNameCenter)) {
            decoratedNamesLine(Array(suras.prefix(1)))
                .frame(width: 0)
                .hidden()
                .accessibilityHidden(true)
            MultipartText("\(suras: suras)")
                .view(ofSize: size, alignment: .trailing)
        }
    }

    // MARK: Private

    private func decoratedNamesLine(_ suras: [Sura]) -> some View {
        MultipartText("\(suras: suras, nameStyle: .decorated)")
            .view(ofSize: size, alignment: .trailing, allowsWrapping: false)
    }
}
