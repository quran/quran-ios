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

    public func localizedCoordinate(locale: Locale = .preferredLanguageLocale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale.fixedLocaleNumbers()
        return "\(formatter.format(sura.suraNumber)):\(formatter.format(ayah))"
    }

    public var localizedName: String {
        let suraName = sura.localizedName()
        return "\(suraName), \(localizedAyahNumber)"
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

        let fraction: String? = switch reminder {
        case 1: lAndroid("quran_rob3")
        case 2: lAndroid("quran_nos")
        case 3: lAndroid("quran_talt_arb3")
        default: nil
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

    public func localizedName(withPrefix: Bool = false, language: Language? = nil) -> String {
        var suraName = l("sura_names[\(suraNumber - 1)]", table: .suras, language: language)
        if withPrefix {
            suraName = lFormat("quran_sura_title", table: .android, language: language, suraName)
        }
        return suraName
    }
}
