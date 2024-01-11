//
//  MultipartText.swift
//
//
//  Created by Mohamed Afifi on 2023-07-14.
//

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

    var body: some View {
        switch part {
        case .plain(let text):
            Text(text)
                .font(size.plainFont)
        case .highlighting(let text, let ranges, let lineLimit):
            highlighting(text: text, ranges: ranges)
                .lineLimit(lineLimit)
                .font(size.plainFont)
        case .sura(let text):
            if NSLocale.preferredLanguages.first != "ar" {
                Text(text)
                    .padding(.top, 5)
                    .frame(alignment: .center)
                    .font(size.suraFont)
            }
        case .verse(let text, let color, let lineLimit):
            Text(text)
                .lineLimit(lineLimit)
                .font(size.verseFont)
                .padding(versePadding)
                .background(color)
        }
    }

    // MARK: Private

    @ScaledMetric private var versePadding = 5

    private func highlighting(text: String, ranges: [HighlightingRange]) -> Text {
        if #available(iOS 15, *) {
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
        } else {
            return Text(text)
        }
    }
}

private enum TextPart {
    case plain(text: String)
    case highlighting(text: String, ranges: [HighlightingRange], lineLimit: Int?)
    case sura(text: String)
    case verse(text: String, color: Color, lineLimit: Int?)

    // MARK: Internal

    var rawValue: String {
        switch self {
        case .plain(let text), .highlighting(let text, _, _), .sura(let text), .verse(let text, _, _):
            return text
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

        public mutating func appendInterpolation(sura: String) {
            parts.append(.sura(text: sura))
        }

        public mutating func appendInterpolation(verse: String, color: Color, lineLimit: Int? = nil) {
            parts.append(.verse(text: verse, color: color, lineLimit: lineLimit))
        }

        public mutating func appendInterpolation(_ text: String, lineLimit: Int? = nil, highlighting: [HighlightingRange]) {
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
        case body
        case caption
        case footnote

        // MARK: Internal

        var plainFont: Font {
            switch self {
            case .body: return .body
            case .footnote: return .footnote
            case .caption: return .caption
            }
        }

        var suraFont: Font {
            switch self {
            case .body: return .custom(.suraNames, size: 20, relativeTo: .body)
            case .footnote: return .custom(.suraNames, size: 16, relativeTo: .footnote)
            case .caption: return .custom(.suraNames, size: 15, relativeTo: .caption)
            }
        }

        var verseFont: Font {
            switch self {
            case .body: return .custom(.quran, size: 20, relativeTo: .body)
            case .footnote: return .custom(.suraNames, size: 16, relativeTo: .footnote)
            case .caption: return .custom(.quran, size: 15, relativeTo: .caption)
            }
        }
    }

    public mutating func append(_ other: MultipartText) {
        parts.append(contentsOf: other.parts)
    }

    // MARK: Internal

    enum FontSize {
        case body
        case caption

        // MARK: Internal

        var plainFont: Font {
            switch self {
            case .body: return .body
            case .caption: return .caption
            }
        }

        var suraFont: Font {
            switch self {
            case .body: return .custom(.suraNames, size: 20, relativeTo: .body)
            case .caption: return .custom(.suraNames, size: 17, relativeTo: .caption)
            }
        }

        var verseFont: Font {
            switch self {
            case .body: return .custom(.quran, size: 20, relativeTo: .body)
            case .caption: return .custom(.quran, size: 17, relativeTo: .caption)
            }
        }
    }

    var rawValue: String {
        parts.map(\.rawValue).joined()
    }

    func view(ofSize size: FontSize) -> some View {
        MultiPartTextView(text: self, size: size)
    }

    // MARK: Fileprivate

    fileprivate var parts: [TextPart]
}

extension MultipartText {
    public static func text(_ plain: String) -> MultipartText {
        MultipartText(stringLiteral: plain)
    }
}

public struct MultiPartTextView: View {
    // MARK: Lifecycle

    public init(text: MultipartText, size: MultipartText.FontSize, alignment: Alignment = .leading) {
        self.text = text
        self.size = size
        self.alignment = alignment
    }

    // MARK: Public

    public var body: some View {
        wrap {
            ForEach(0 ..< text.parts.count, id: \.self) { i in
                TextPartView(part: text.parts[i], size: size)
            }
        }
    }

    // MARK: Internal

    let text: MultipartText
    let size: MultipartText.FontSize
    let alignment: Alignment

    // MARK: Private

    @ViewBuilder
    private func wrap(@ViewBuilder content: () -> some View) -> some View {
        if #available(iOS 16.0, *) {
            WrappingHStack(alignment: alignment, horizontalSpacing: 0) {
                content()
            }
        } else {
            HStack(spacing: 0) {
                content()
            }
        }
    }
}
