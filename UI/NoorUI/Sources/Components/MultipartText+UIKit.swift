//
//  MultipartText+UIKit.swift
//

import Foundation
import Localization
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
        case .ayah(let ayah, let emphasizesSura):
            QuranReference.ayah(ayah).attributedString(
                size: size,
                locale: locale,
                emphasizesSura: emphasizesSura
            )
        case .quran(let text, let color, _):
            NSAttributedString(string: text, attributes: [
                .backgroundColor: UIColor(color),
                .font: size.quranUIFont,
            ])
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
}
