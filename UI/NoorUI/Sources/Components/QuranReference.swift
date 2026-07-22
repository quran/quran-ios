//
//  QuranReference.swift
//

import Foundation
import Localization
import NoorFont
import QuranKit
import QuranLocalization
import SwiftUI
import UIKit

enum QuranReference {
    case sura(Sura)
    case ayah(AyahNumber)

    // MARK: Internal

    var accessibilityText: String {
        switch self {
        case .sura(let sura):
            sura.localizedName()
        case .ayah(let ayah):
            ayah.localizedName
        }
    }

    fileprivate var decoratedGlyph: String {
        let codePoint = Self.decoratedSuraNameCodePoints[sura.suraNumber - 1]
        return String(UnicodeScalar(codePoint)!)
    }

    fileprivate func localizedName(locale: Locale) -> String? {
        locale.isArabicLanguage ? nil : sura.localizedName()
    }

    fileprivate func coordinate(locale: Locale) -> String? {
        switch self {
        case .sura:
            nil
        case .ayah(let ayah):
            ayah.localizedCoordinate(locale: locale)
        }
    }

    func rawValue(locale: Locale) -> String {
        var components = [String]()
        if let localizedName = localizedName(locale: locale) {
            components.append(localizedName)
        }
        components.append(decoratedGlyph)

        let suraReference = components.joined(separator: " ")
        if let coordinate = coordinate(locale: locale) {
            return "\(suraReference) · \(coordinate)"
        }
        return suraReference
    }

    func attributedString(
        size: MultipartText.FontSize,
        locale: Locale,
        emphasizesSura: Bool = false
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        if let localizedName = localizedName(locale: locale) {
            result.append(NSAttributedString(
                string: localizedName,
                attributes: [.font: size.plainUIFont(emphasized: emphasizesSura)]
            ))
            result.append(NSAttributedString(string: " "))
        }

        let glyphAttributes: [NSAttributedString.Key: Any] = [
            .font: size.suraUIFont,
            .baselineOffset: -2,
        ]
        result.append(NSAttributedString(string: decoratedGlyph, attributes: glyphAttributes))

        if let coordinate = coordinate(locale: locale) {
            result.append(NSAttributedString(
                string: " · \(coordinate)",
                attributes: [.font: size.plainUIFont]
            ))
        }
        return result
    }

    // MARK: Private

    private var sura: Sura {
        switch self {
        case .sura(let sura):
            sura
        case .ayah(let ayah):
            ayah.sura
        }
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

struct QuranReferenceView: View {
    // MARK: Lifecycle

    init(
        reference: QuranReference,
        size: MultipartText.FontSize,
        emphasizesSura: Bool = false
    ) {
        self.reference = reference
        self.size = size
        self.emphasizesSura = emphasizesSura
    }

    // MARK: Internal

    let reference: QuranReference
    let size: MultipartText.FontSize
    let emphasizesSura: Bool

    @Environment(\.locale) private var locale
    @ScaledMetric private var spacing = 4
    @ScaledMetric private var glyphTopPadding = 5

    var body: some View {
        HStack(spacing: spacing) {
            if let localizedName = reference.localizedName(locale: locale) {
                Text(localizedName)
                    .font(size.plainFont)
                    .fontWeight(emphasizesSura ? .heavy : nil)
            }

            Text(reference.decoratedGlyph)
                .font(size.suraFont)
                .padding(.top, glyphTopPadding)

            if let coordinate = reference.coordinate(locale: locale) {
                Text("·")
                    .font(size.plainFont)
                Text(coordinate)
                    .font(size.plainFont)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reference.accessibilityText)
    }
}

extension MultipartText.FontSize {
    var plainUIFont: UIFont {
        UIFont.preferredFont(forTextStyle: uiTextStyle)
    }

    var suraUIFont: UIFont {
        UIFontMetrics(forTextStyle: uiTextStyle).scaledFont(
            for: UIFont(.suraNames, size: suraPointSize)
        )
    }

    var quranUIFont: UIFont {
        UIFontMetrics(forTextStyle: uiTextStyle).scaledFont(
            for: UIFont(.quran, size: quranPointSize)
        )
    }

    func plainUIFont(emphasized: Bool) -> UIFont {
        guard emphasized else { return plainUIFont }
        return UIFont.systemFont(ofSize: plainUIFont.pointSize, weight: .heavy)
    }

    private var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .title3: .title3
        case .body: .body
        case .subheadline: .subheadline
        case .caption: .caption1
        case .footnote: .footnote
        }
    }

    private var suraPointSize: CGFloat {
        switch self {
        case .title3: 24
        case .body: 20
        case .subheadline: 19
        case .caption: 15
        case .footnote: 16
        }
    }

    private var quranPointSize: CGFloat {
        switch self {
        case .title3: 24
        case .body: 20
        case .subheadline: 18
        case .caption: 15
        case .footnote: 16
        }
    }
}
