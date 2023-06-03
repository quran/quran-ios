//
//  QuranKit+Localization.swift
//
//
//  Created by Mohamed Afifi on 2021-12-10.
//

import Foundation
import Localization
import QuranKit

extension AyahNumber {
    public var localizedAyahNumber: String { lFormat("quran_ayah", table: .android, ayah) }
    public var localizedName: String {
        let suraName = sura.localizedName()
        return "\(suraName), \(localizedAyahNumber)"
    }

    public var localizedNameWithSuraNumber: String {
        let localizedSura = sura.localizedName(withNumber: true)
        return "\(localizedSura) - \(localizedAyahNumber)"
    }
}

extension Juz {
    public var localizedName: String {
        lFormat("juz2_description", table: .android, NumberFormatter.shared.format(juzNumber))
    }
}

extension Page {
    public var localizedName: String {
        "\(lAndroid("quran_page")) \(NumberFormatter.shared.format(pageNumber))"
    }

    public var localizedNumber: String {
        NumberFormatter.shared.format(pageNumber)
    }

    public var localizedQuarterName: String {
        let juzDescription = startJuz.localizedName
        if let quarter {
            return [juzDescription, quarter.localizedName].joined(separator: ", ")
        } else {
            return juzDescription
        }
    }
}

extension Hizb {
    public var localizedName: String {
        "\(lAndroid("quran_hizb")) \(NumberFormatter.shared.format(hizbNumber))"
    }
}

extension Quarter {
    public var localizedName: String {
        let rub = quarterNumber - 1
        let reminder = rub % 4

        let fraction: String?
        switch reminder {
        case 1: fraction = lAndroid("quran_rob3")
        case 2: fraction = lAndroid("quran_nos")
        case 3: fraction = lAndroid("quran_talt_arb3")
        default: fraction = nil
        }

        let hizbString = hizb.localizedName
        let components = [fraction, hizbString].compactMap { $0 }
        return components.joined(separator: " ")
    }
}

extension Sura {
    public var localizedSuraNumber: String {
        NumberFormatter.shared.format(suraNumber)
    }

    public func localizedName(withPrefix: Bool = false, withNumber: Bool = false, language: Language? = nil) -> String {
        var suraName = l("sura_names[\(suraNumber - 1)]", table: .suras, language: language)
        if withPrefix {
            suraName = lFormat("quran_sura_title", table: .android, language: language, suraName)
        }
        if withNumber {
            suraName = "\(localizedSuraNumber). \(suraName)"
        }
        return suraName
    }
}

extension Sura {
    public var arabicSuraName: String {
        let codePoint = Self.decoratedSurasCodePoints[suraNumber - 1]
        let scalar = UnicodeScalar(codePoint)!
        return String(scalar)
    }

    private static let decoratedSurasCodePoints = [
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
