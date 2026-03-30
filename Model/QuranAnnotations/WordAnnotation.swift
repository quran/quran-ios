//
//  WordAnnotation.swift
//  Quran
//
//  Created for Quran.com iOS app.
//

import Foundation
import QuranKit
import SwiftUI

/// Per-word display annotations: tajweed colour and transliteration.
public struct WordAnnotation: Equatable, Sendable {
    // MARK: Lifecycle

    public init(wordIndex: Int, verse: AyahNumber, tajweedColor: TajweedColor? = nil, transliteration: String? = nil) {
        self.wordIndex = wordIndex
        self.verse = verse
        self.tajweedColor = tajweedColor
        self.transliteration = transliteration
    }

    // MARK: Public

    /// 1-based position of the word within its verse.
    public let wordIndex: Int
    public let verse: AyahNumber
    /// Tajweed rule colour to overlay on this word, if any.
    public let tajweedColor: TajweedColor?
    /// Romanised transliteration text to display below this word, if any.
    public let transliteration: String?
}

/// Tajweed rule colours matching quran.com's palette.
public enum TajweedColor: String, CaseIterable, Sendable {
    case hamzaWasl       = "ham_wasl"
    case silent          = "slnt"
    case laamShamsiyya   = "laam_shamsiyya"
    case maddaNormal     = "madda_normal"
    case maddaMandatory  = "madda_wajib"
    case maddaPermissible = "madda_jaiz"
    case ghunna          = "ghunna"
    case ikhfaAkbar      = "ikhfa_akbar"
    case ikhfaShafawi    = "ikhfa_shafawi"
    case idghamShafawi   = "idgham_shafawi"
    case idghamGhunna    = "idgham_ghunna"
    case idghamWoGhunna  = "idgham_wo_ghunna"
    case idghamMutajanisayn = "idgham_mutajanisayn"
    case idghamMutaqaribain = "idgham_mutaqaribain"
    case iqlab           = "iqlab"
    case qalqala         = "qalqala"
    case tafkhim         = "tafkhim"

    /// Hex colour value (RRGGBB) for each rule, matching quran.com.
    public var hexColor: String {
        switch self {
        case .hamzaWasl:             return "AAAAAA"
        case .silent:                return "AAAAAA"
        case .laamShamsiyya:         return "AAAAAA"
        case .maddaNormal:           return "537FFF"
        case .maddaMandatory:        return "000EBC"
        case .maddaPermissible:      return "4050FF"
        case .ghunna:                return "FF00FF"
        case .ikhfaAkbar:            return "9400FF"
        case .ikhfaShafawi:          return "9400FF"
        case .idghamShafawi:         return "169200"
        case .idghamGhunna:          return "169200"
        case .idghamWoGhunna:        return "169200"
        case .idghamMutajanisayn:    return "169200"
        case .idghamMutaqaribain:    return "169200"
        case .iqlab:                 return "FF6600"
        case .qalqala:               return "DD6600"
        case .tafkhim:               return "FF0000"
        }
    }

    public init?(cssClass: String) {
        self.init(rawValue: cssClass)
    }

    /// SwiftUI Color from the hex string.
    public var swiftUIColor: Color {
        let hex = hexColor
        let r = Double(Int(hex.prefix(2), radix: 16) ?? 0) / 255
        let g = Double(Int(hex.dropFirst(2).prefix(2), radix: 16) ?? 0) / 255
        let b = Double(Int(hex.dropFirst(4).prefix(2), radix: 16) ?? 0) / 255
        return Color(red: r, green: g, blue: b)
    }
}
