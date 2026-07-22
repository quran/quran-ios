//
//  MultipartText.swift
//
//
//  Created by Mohamed Afifi on 2023-07-14.
//

import Foundation
import QuranKit
import QuranLocalization
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
        case .sura(let sura, let format):
            referenceText(Text(sura.referenceName(format: format)), sura: sura)
        case .ayah(let ayah, let format, let ranges):
            referenceText(
                highlighting(text: ayah.referenceName(format: format), ranges: ranges),
                sura: ayah.sura
            )
        case .quran(let text, let color, let lineLimit):
            Text(text)
                .lineLimit(lineLimit)
                .font(size.quranFont)
                .padding(quranTextPadding)
                .background(color)
        }
    }

    // MARK: Private

    @ScaledMetric private var quranTextPadding = 5

    @ViewBuilder
    private func referenceText(_ text: Text, sura: Sura) -> some View {
        HStack {
            text
                .font(size.plainFont)
            if NSLocale.preferredLanguages.first != "ar" {
                Text(sura.decoratedSuraNameGlyph)
                    .padding(.top, 5)
                    .frame(alignment: .center)
                    .font(size.suraFont)
            }
        }
    }

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

private enum TextPart {
    case plain(text: String)
    case highlighting(text: String, ranges: [HighlightingRange], lineLimit: Int?)
    case sura(Sura, format: MultipartText.SuraReferenceFormat)
    case ayah(AyahNumber, format: MultipartText.AyahReferenceFormat, highlighting: [HighlightingRange])
    case quran(text: String, color: Color, lineLimit: Int?)

    // MARK: Internal

    var rawValue: String {
        switch self {
        case .plain(let text), .highlighting(let text, _, _):
            text
        case .sura(let sura, let format):
            "\(sura.referenceName(format: format)) \(sura.decoratedSuraNameGlyph)"
        case .ayah(let ayah, let format, _):
            "\(ayah.referenceName(format: format)) \(ayah.sura.decoratedSuraNameGlyph)"
        case .quran(let text, _, _):
            text
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

        public mutating func appendInterpolation(
            sura: Sura,
            format: SuraReferenceFormat = .name
        ) {
            parts.append(.sura(sura, format: format))
        }

        public mutating func appendInterpolation(
            ayah: AyahNumber,
            format: AyahReferenceFormat = .descriptive,
            highlighting: [HighlightingRange] = []
        ) {
            parts.append(.ayah(ayah, format: format, highlighting: highlighting))
        }

        public mutating func appendInterpolation(
            quran text: String,
            color: Color = .clear,
            lineLimit: Int? = nil
        ) {
            parts.append(.quran(text: text, color: color, lineLimit: lineLimit))
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

    public enum SuraReferenceFormat {
        case name
        case numbered
    }

    public enum AyahReferenceFormat {
        case compact
        case descriptive
        case numberedSura
    }

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

        var quranFont: Font {
            switch self {
            case .body: return .custom(.quran, size: 20, relativeTo: .body)
            case .footnote: return .custom(.quran, size: 16, relativeTo: .footnote)
            case .caption: return .custom(.quran, size: 15, relativeTo: .caption)
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

    // MARK: Internal

    var rawValue: String {
        parts.map(\.rawValue).joined()
    }

    // MARK: Fileprivate

    fileprivate var parts: [TextPart]
}

extension MultipartText {
    public static func text(_ plain: String) -> MultipartText {
        MultipartText(stringLiteral: plain)
    }
}

private extension Sura {
    func referenceName(format: MultipartText.SuraReferenceFormat) -> String {
        switch format {
        case .name: localizedName()
        case .numbered: localizedName(withNumber: true)
        }
    }
}

private extension AyahNumber {
    func referenceName(format: MultipartText.AyahReferenceFormat) -> String {
        switch format {
        case .compact: localizedCompactName
        case .descriptive: localizedName
        case .numberedSura: localizedNameWithSuraNumber
        }
    }
}

extension Sura {
    // TODO: make private
    var decoratedSuraNameGlyph: String {
        let codePoint = Self.decoratedSuraNameCodePoints[suraNumber - 1]
        return String(UnicodeScalar(codePoint)!)
    }

    private static let decoratedSuraNameCodePoints = [
        0xE904, 0xE905, 0xE906, 0xE907, 0xE908, 0xE90B,
        0xE90C, 0xE90D, 0xE90E, 0xE90F, 0xE910, 0xE911,
        0xE912, 0xE913, 0xE914, 0xE915, 0xE916, 0xE917,
        0xE918, 0xE919, 0xE91A, 0xE91B, 0xE91C, 0xE91D,
        0xE91E, 0xE91F, 0xE920, 0xE921, 0xE922, 0xE923,
        0xE924, 0xE925, 0xE926, 0xE92E, 0xE92F, 0xE930,
        0xE931, 0xE909, 0xE90A, 0xE927, 0xE928, 0xE929,
        0xE92A, 0xE92B, 0xE92C, 0xE92D, 0xE932, 0xE902,
        0xE933, 0xE934, 0xE935, 0xE936, 0xE937, 0xE938,
        0xE939, 0xE93A, 0xE93B, 0xE93C, 0xE900, 0xE901,
        0xE941, 0xE942, 0xE943, 0xE944, 0xE945, 0xE946,
        0xE947, 0xE948, 0xE949, 0xE94A, 0xE94B, 0xE94C,
        0xE94D, 0xE94E, 0xE94F, 0xE950, 0xE951, 0xE952,
        0xE93D, 0xE93E, 0xE93F, 0xE940, 0xE953, 0xE954,
        0xE955, 0xE956, 0xE957, 0xE958, 0xE959, 0xE95A,
        0xE95B, 0xE95C, 0xE95D, 0xE95E, 0xE95F, 0xE960,
        0xE961, 0xE962, 0xE963, 0xE964, 0xE965, 0xE966,
        0xE967, 0xE968, 0xE969, 0xE96A, 0xE96B, 0xE96C,
        0xE96D, 0xE96E, 0xE96F, 0xE970, 0xE971, 0xE972,
    ]
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
