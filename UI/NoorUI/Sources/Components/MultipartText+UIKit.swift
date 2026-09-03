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
        let result = NSMutableAttributedString()
        for part in parts {
            result.append(part.attributedString(ofSize: size, locale: .preferredLanguageLocale))
        }
        return result
    }
}

private extension TextPart {
    func attributedString(ofSize size: MultipartText.FontSize, locale: Locale) -> NSAttributedString {
        switch self {
        case .plain(let text):
            NSAttributedString(string: text, attributes: [.font: size.plainUIFont])
        case .highlighting(let text, let ranges, _):
            highlightedAttributedString(text: text, ranges: ranges, size: size)
        case .sura(let sura):
            QuranReference.sura(sura).attributedString(size: size, locale: locale)
        case .ayah(let ayah, let emphasizesSura, let decorationHidden):
            QuranReference.ayah(ayah, decorationHidden: decorationHidden).attributedString(
                size: size,
                locale: locale,
                emphasizesSura: emphasizesSura
            )
        case .ayahCoordinate(let ayah):
            NSAttributedString(
                string: ayah.localizedCoordinate(locale: locale),
                attributes: [.font: size.plainUIFont]
            )
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
