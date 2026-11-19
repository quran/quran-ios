//
//  MultipartText+UIKit.swift
//

import Foundation
import Localization
import QuranText
import SwiftUI
import UIKit

extension MultipartText {
    public func attributedString(ofSize size: FontSize) -> NSAttributedString {
        attributedString(ofSize: size, locale: .preferredLanguageLocale)
    }

    func attributedString(ofSize size: FontSize, locale: Locale) -> NSAttributedString {
        let result = NSMutableAttributedString()
        // A decorated sura name is a private-use character, which reads left to right, and the coordinates are
        // isolated left to right, so a label would lay the text out left to right. A leading right-to-left mark
        // keeps the paragraph right to left without overriding a label's alignment, as a paragraph style would.
        if locale.isRightToLeft {
            result.append(NSAttributedString(string: "\u{200F}", attributes: [.font: size.plainUIFont]))
        }
        result.append(TextPart.attributedString(parts, ofSize: size, locale: locale))
        return result
    }
}

private extension TextPart {
    /// In right-to-left text, the text after a decorated glyph sits on its left, so kerning widens its first character.
    static func attributedString(_ parts: [TextPart], ofSize size: MultipartText.FontSize, locale: Locale) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var spacesNextPart = false
        for part in parts {
            let string = NSMutableAttributedString(attributedString: part.attributedString(ofSize: size, locale: locale))
            guard string.length > 0 else { continue }
            // Kerning a bidi control, like the isolate around a coordinate, widens nothing.
            if spacesNextPart, let index = string.string.utf16.firstIndex(where: { !Self.bidiControls.contains($0) }) {
                let location = string.string.utf16.distance(from: string.string.utf16.startIndex, to: index)
                string.addAttributes(size.decoratedGlyphSpacingAttributes, range: NSRange(location: location, length: 1))
            }
            result.append(string)
            spacesNextPart = locale.isRightToLeft && part.endsWithDecoratedGlyph(locale: locale)
        }
        return result
    }

    static let bidiControls: Set<UInt16> = [0x061C, 0x200E, 0x200F, 0x202A, 0x202B, 0x202C, 0x202D, 0x202E, 0x2066, 0x2067, 0x2068, 0x2069]

    func endsWithDecoratedGlyph(locale: Locale) -> Bool {
        switch self {
        case .sura(let sura, _, let nameStyle):
            QuranReference.sura(sura, nameStyle: nameStyle).endsWithDecoratedGlyph(locale: locale)
        case .suras(let suras, let nameStyle):
            suras.last.map { QuranReference.sura($0, nameStyle: nameStyle).endsWithDecoratedGlyph(locale: locale) } ?? false
        case .accessibilityLabeled(let parts, _), .unbreakable(let parts):
            parts.last { !$0.isEmpty }?.endsWithDecoratedGlyph(locale: locale) ?? false
        case .plain, .highlighting, .ayah, .ayahs, .quran:
            false
        }
    }

    func attributedString(ofSize size: MultipartText.FontSize, locale: Locale) -> NSAttributedString {
        switch self {
        case .plain(let text):
            NSAttributedString(string: text, attributes: [.font: size.plainUIFont])
        case .highlighting(let text, let ranges, _):
            highlightedAttributedString(text: text, ranges: ranges, size: size)
        case .sura(let sura, let emphasizesSura, let nameStyle):
            QuranReference.sura(sura, nameStyle: nameStyle).attributedString(size: size, locale: locale, emphasizesSura: emphasizesSura)
        case .ayah(let ayah, let emphasizesSura, let nameStyle):
            QuranReference.ayah(ayah, nameStyle: nameStyle).attributedString(
                size: size,
                locale: locale,
                emphasizesSura: emphasizesSura
            )
        case .suras(let suras, let nameStyle):
            suras.enumerated().reduce(into: NSMutableAttributedString()) { result, element in
                if element.offset > 0 {
                    result.append(NSAttributedString(string: SuraNamesView.separator, attributes: [.font: size.plainUIFont]))
                }
                result.append(QuranReference.sura(element.element, nameStyle: nameStyle).attributedString(size: size, locale: locale))
            }
        case .ayahs(let ayahs, let nameStyle):
            QuranReference.ayahs(ayahs, nameStyle: nameStyle).attributedString(size: size, locale: locale)
        case .accessibilityLabeled(let parts, _), .unbreakable(let parts):
            TextPart.attributedString(parts, ofSize: size, locale: locale)
        case .quran(let text, let quranFont, let color, _, let highlighting):
            highlightedQuranAttributedString(
                text: text,
                quranFont: quranFont,
                ranges: highlighting,
                color: color,
                size: size
            )
        }
    }

    func highlightedAttributedString(
        text: String,
        ranges: [HighlightingRange],
        size: MultipartText.FontSize
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: [.font: size.plainUIFont])
        for highlight in ranges {
            let range = NSRange(highlight.range, in: text)
            if let foregroundColor = highlight.foregroundColor {
                result.addAttribute(.foregroundColor, value: UIColor(foregroundColor), range: range)
            }
            if highlight.fontWeight != nil {
                result.addAttribute(.font, value: size.plainUIFont(emphasized: true), range: range)
            }
        }
        return result
    }

    func highlightedQuranAttributedString(
        text: QuranText,
        quranFont: QuranFont,
        ranges: [HighlightingRange],
        color: Color,
        size: MultipartText.FontSize
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text.text, attributes: [
            .backgroundColor: UIColor(color),
            .font: size.quranUIFont(quranFont),
        ])
        for highlight in ranges {
            let range = NSRange(highlight.range, in: text.text)
            if let foregroundColor = highlight.foregroundColor {
                result.addAttribute(.foregroundColor, value: UIColor(foregroundColor), range: range)
            }
            if highlight.fontWeight != nil {
                result.addAttribute(.font, value: size.quranUIFont(quranFont, emphasized: true), range: range)
            }
        }
        if quranFont == .indoPak {
            for markerRange in text.ayahMarkerRanges {
                result.addAttribute(
                    .font,
                    value: size.quranUIFont(.uthmanicHafs),
                    range: NSRange(markerRange, in: text.text)
                )
            }
        }
        return result
    }
}
