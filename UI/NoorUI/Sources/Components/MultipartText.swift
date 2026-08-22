//
//  MultipartText.swift
//
//
//  Created by Mohamed Afifi on 2023-07-14.
//

import Foundation
import Localization
import QuranKit
import QuranLocalization
import QuranText
import SwiftUI
import UIx

public struct HighlightingRange {
    // MARK: Lifecycle

    public init(_ range: Range<String.Index>, foregroundColor: Color? = nil, fontWeight: Font.Weight? = nil) {
        self.range = range
        self.foregroundColor = foregroundColor
        self.fontWeight = fontWeight
    }

    // MARK: Internal

    let range: Range<String.Index>
    let foregroundColor: Color?
    let fontWeight: Font.Weight?
}

private struct TextPartView: View {
    // MARK: Internal

    let part: TextPart
    let size: MultipartText.FontSize

    @Environment(\.locale) private var locale

    var body: some View {
        switch part {
        case .plain(let text):
            Text(text)
                .font(size.plainFont)
        case .highlighting(let text, let ranges, let lineLimit):
            highlighting(text: text, ranges: ranges)
                .optionalLineLimit(lineLimit)
                .font(size.plainFont)
        case .sura(let sura):
            QuranReferenceView(reference: .sura(sura), size: size)
        case .ayah(let ayah, let emphasizesSura):
            QuranReferenceView(
                reference: .ayah(ayah),
                size: size,
                emphasizesSura: emphasizesSura
            )
        case .ayahCoordinate(let ayah):
            Text(ayah.localizedCoordinate(locale: locale))
                .font(size.plainFont)
                .environment(\.layoutDirection, .leftToRight)
        case .quran(let text, let quranFont, let color, let lineLimit, let highlighting):
            QuranTextView(
                text,
                font: size.quranFont(quranFont),
                highlighting: highlighting,
                fontOverrides: quranFont == .indoPak ? text.ayahMarkerRanges.map {
                    QuranTextFontOverride(
                        range: $0,
                        quranFont: .uthmanicHafs,
                        font: size.quranFont(.uthmanicHafs)
                    )
                } : []
            )
            .optionalLineLimit(lineLimit)
            .padding(.vertical, size.quranTextVerticalPadding(quranFont))
            .padding(quranTextPadding)
            .background(color)
        }
    }

    // MARK: Private

    @ScaledMetric private var quranTextPadding = 5

    private func highlighting(text: String, ranges: [HighlightingRange]) -> Text {
        var attributedString = AttributedString(text)
        for highlight in ranges {
            if let start = AttributedString.Index(highlight.range.lowerBound, within: attributedString),
               let end = AttributedString.Index(highlight.range.upperBound, within: attributedString)
            {
                if let foregroundColor = highlight.foregroundColor {
                    attributedString[start ..< end].foregroundColor = foregroundColor
                }
                if let fontWeight = highlight.fontWeight {
                    attributedString[start ..< end].font = size.plainFont.weight(fontWeight)
                }
            }
        }
        return Text(attributedString)
    }
}

private struct OptionalLineLimitModifier: ViewModifier {
    let lineLimit: Int?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let lineLimit {
            content.lineLimit(lineLimit)
        } else {
            content
        }
    }
}

private extension View {
    func optionalLineLimit(_ lineLimit: Int?) -> some View {
        modifier(OptionalLineLimitModifier(lineLimit: lineLimit))
    }
}

enum TextPart {
    case plain(text: String)
    case highlighting(text: String, ranges: [HighlightingRange], lineLimit: Int?)
    case sura(Sura)
    case ayah(AyahNumber, emphasizesSura: Bool)
    case ayahCoordinate(AyahNumber)
    case quran(
        text: QuranText,
        font: QuranFont,
        color: Color,
        lineLimit: Int?,
        highlighting: [HighlightingRange]
    )

    // MARK: Internal

    func rawValue(locale: Locale) -> String {
        switch self {
        case .plain(let text), .highlighting(let text, _, _):
            text
        case .sura(let sura):
            QuranReference.sura(sura).rawValue(locale: locale)
        case .ayah(let ayah, _):
            QuranReference.ayah(ayah).rawValue(locale: locale)
        case .ayahCoordinate(let ayah):
            ayah.localizedCoordinate(locale: locale)
        case .quran(let text, _, _, _, _):
            text.text
        }
    }

    var accessibilityText: String {
        switch self {
        case .plain(let text), .highlighting(let text, _, _):
            text
        case .sura(let sura):
            QuranReference.sura(sura).accessibilityText
        case .ayah(let ayah, _):
            QuranReference.ayah(ayah).accessibilityText
        case .ayahCoordinate(let ayah):
            ayah.localizedCoordinate()
        case .quran(let text, _, _, _, _):
            text.text
        }
    }
}

public struct MultipartText: ExpressibleByStringInterpolation {
    public struct StringInterpolation: StringInterpolationProtocol {
        // MARK: Lifecycle

        public init(literalCapacity: Int, interpolationCount: Int) {}

        // MARK: Public

        public mutating func appendLiteral(_ literal: String) {
            parts.append(.plain(text: literal))
        }

        public mutating func appendInterpolation(sura: Sura) {
            parts.append(.sura(sura))
        }

        public mutating func appendInterpolation(
            ayah: AyahNumber,
            emphasizingSura: Bool = false
        ) {
            parts.append(.ayah(ayah, emphasizesSura: emphasizingSura))
        }

        public mutating func appendInterpolation(ayahRange range: ClosedRange<AyahNumber>) {
            let start = range.lowerBound
            let end = range.upperBound
            parts.append(.ayah(start, emphasizesSura: false))

            guard start != end else {
                return
            }

            parts.append(.plain(text: " - "))
            if start.sura == end.sura {
                parts.append(.ayahCoordinate(end))
            } else {
                parts.append(.ayah(end, emphasizesSura: false))
            }
        }

        public mutating func appendInterpolation(
            quran text: QuranText,
            font: QuranFont,
            color: Color = .clear,
            lineLimit: Int? = nil,
            highlighting: [HighlightingRange] = []
        ) {
            parts.append(
                .quran(
                    text: text,
                    font: font,
                    color: color,
                    lineLimit: lineLimit,
                    highlighting: highlighting
                )
            )
        }

        public mutating func appendInterpolation(
            _ text: String,
            lineLimit: Int? = nil,
            highlighting: [HighlightingRange]
        ) {
            parts.append(.highlighting(text: text, ranges: highlighting, lineLimit: lineLimit))
        }

        public mutating func appendInterpolation(_ plain: String) {
            parts.append(.plain(text: plain))
        }

        public mutating func appendInterpolation(_ other: MultipartText) {
            parts.append(contentsOf: other.parts)
        }

        // MARK: Fileprivate

        fileprivate var parts: [TextPart] = []
    }

    // MARK: Lifecycle

    public init(stringInterpolation: StringInterpolation) {
        parts = stringInterpolation.parts
    }

    public init(stringLiteral value: StringLiteralType) {
        parts = [.plain(text: value)]
    }

    // MARK: Public

    public enum FontSize {
        case title3
        case body
        case subheadline
        case caption
        case footnote

        // MARK: Internal

        var plainFont: Font {
            switch self {
            case .title3: return .title3
            case .body: return .body
            case .subheadline: return .subheadline
            case .footnote: return .footnote
            case .caption: return .caption
            }
        }

        var suraFont: Font {
            switch self {
            case .title3: return .custom(.suraNames, size: 24, relativeTo: .title3)
            case .body: return .custom(.suraNames, size: 20, relativeTo: .body)
            case .subheadline: return .custom(.suraNames, size: 19, relativeTo: .subheadline)
            case .footnote: return .custom(.suraNames, size: 16, relativeTo: .footnote)
            case .caption: return .custom(.suraNames, size: 15, relativeTo: .caption)
            }
        }

        func quranFont(_ quranFont: QuranFont) -> Font {
            switch self {
            case .title3: return .custom(quranFont.fontName, size: 24, relativeTo: .title3)
            case .body: return .custom(quranFont.fontName, size: 20, relativeTo: .body)
            case .subheadline: return .custom(quranFont.fontName, size: 18, relativeTo: .subheadline)
            case .footnote: return .custom(quranFont.fontName, size: 16, relativeTo: .footnote)
            case .caption: return .custom(quranFont.fontName, size: 15, relativeTo: .caption)
            }
        }
    }

    public mutating func append(_ other: MultipartText) {
        parts.append(contentsOf: other.parts)
    }

    public func view(
        ofSize size: FontSize,
        alignment: Alignment = .leading,
        allowsWrapping: Bool = true
    ) -> some View {
        MultiPartTextView(text: self, size: size, alignment: alignment, allowsWrapping: allowsWrapping)
    }

    // MARK: Public

    public var accessibilityText: String {
        parts.map(\.accessibilityText).joined()
    }

    // MARK: Internal

    var rawValue: String {
        rawValue(locale: .preferredLanguageLocale)
    }

    func rawValue(locale: Locale) -> String {
        parts.map { $0.rawValue(locale: locale) }.joined()
    }

    var parts: [TextPart]
}

extension MultipartText {
    public static func text(_ plain: String) -> MultipartText {
        MultipartText(stringLiteral: plain)
    }
}

private struct MultiPartTextView: View {
    // MARK: Lifecycle

    let text: MultipartText
    let size: MultipartText.FontSize
    let alignment: Alignment
    let allowsWrapping: Bool

    var body: some View {
        wrap {
            ForEach(0 ..< text.parts.count, id: \.self) { i in
                TextPartView(part: text.parts[i], size: size)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text.accessibilityText)
    }

    @ViewBuilder
    private func wrap(@ViewBuilder content: () -> some View) -> some View {
        if !allowsWrapping {
            HStack(spacing: 0) {
                content()
            }
            .lineLimit(1)
        } else if #available(iOS 16.0, *) {
            WrappingHStack(alignment: alignment, horizontalSpacing: 0, fitContentWidth: true) {
                content()
            }
        } else {
            HStack(spacing: 0) {
                content()
            }
        }
    }
}
