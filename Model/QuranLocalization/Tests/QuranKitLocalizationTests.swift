//
//  QuranKitLocalizationTests.swift
//
//
//  Created by Mohamed Afifi on 2021-12-06.
//

import Localization
import QuranKit
import XCTest
@testable import QuranLocalization

final class QuranKitLocalizationTests: XCTestCase {
    // MARK: Internal

    func testAyahCoordinateLocalization() {
        let ayah = quran.suras[1].verses[254]

        XCTAssertEqual("2:255", ayah.localizedCoordinate(locale: Locale(identifier: "en-CA")))
        XCTAssertEqual("٢:٢٥٥", ayah.localizedCoordinate(locale: Locale(identifier: "ar-SA")))
    }

    func testQuarterLocalization() {
        XCTAssertEqual("Hizb 1", quran.quarters[0].localizedName)
        XCTAssertEqual("¼ Hizb 1", quran.quarters[1].localizedName)
        XCTAssertEqual("½ Hizb 1", quran.quarters[2].localizedName)
        XCTAssertEqual("¾ Hizb 1", quran.quarters[3].localizedName)
        XCTAssertEqual("Hizb 2", quran.quarters[4].localizedName)
    }

    func testPageQuarterInfo() {
        XCTAssertEqual("Juz' 1, Hizb 1", quran.pages[0].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[1].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[2].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[3].localizedQuarterName)
        XCTAssertEqual("Juz' 1, ¼ Hizb 1", quran.pages[4].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[5].localizedQuarterName)
        XCTAssertEqual("Juz' 1, ½ Hizb 1", quran.pages[6].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[7].localizedQuarterName)
        XCTAssertEqual("Juz' 1, ¾ Hizb 1", quran.pages[8].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[9].localizedQuarterName)
        XCTAssertEqual("Juz' 1, Hizb 2", quran.pages[10].localizedQuarterName)
        XCTAssertEqual("Juz' 1", quran.pages[11].localizedQuarterName)
        XCTAssertEqual("Juz' 30, ¾ Hizb 60", quran.pages[598].localizedQuarterName)
        XCTAssertEqual("Juz' 30", quran.pages[599].localizedQuarterName)
    }

    func testPageQuarterInfoSeparatesWithLocalizedComma() throws {
        let page = quran.pages[4]
        let quarter = try XCTUnwrap(page.quarter)

        XCTAssertEqual(
            [page.startJuz.localizedName, quarter.localizedName].joined(separator: l("list.separator.comma")),
            page.localizedQuarterName
        )
    }

    func testAyahName() {
        let ayah = quran.suras[1].verses[254]

        XCTAssertEqual("Al-Baqarah, Ayah 255", ayah.localizedName)
        XCTAssertEqual(
            lFormat("quran.ayah.name", ayah.sura.localizedName(), ayah.localizedAyahNumber),
            ayah.localizedName
        )
    }

    func testPageName() {
        let page = quran.pages[41]

        XCTAssertEqual("Page 42", page.localizedName)
        XCTAssertEqual(lFormat("quran.page.name", NumberFormatter.shared.format(42)), page.localizedName)
    }

    func testArabicReferenceFormatsUseArabicComma() {
        XCTAssertEqual("، ", l("list.separator.comma", language: .arabic))
        XCTAssertEqual(
            "البَقَرَةِ، آية ٢٥٥",
            withoutBidiIsolates(lFormat("quran.ayah.name", language: .arabic, "البَقَرَةِ", "آية ٢٥٥"))
        )
        XCTAssertEqual("الصفحة ٤٢", withoutBidiIsolates(lFormat("quran.page.name", language: .arabic, "٤٢")))
    }

    func testIndoPakSuraNamesUseReadingSpecificEnglishNames() {
        let names = [
            17: "Banī Isrā’īl",
            40: "Al-Mu’min",
            41: "Ḥā-Mīm al-Sajdah",
            76: "Al-Dahr",
            111: "Al-Lahab",
        ]

        for (suraNumber, name) in names {
            XCTAssertEqual(
                name,
                Quran.hafsIndoPak.suras[suraNumber - 1].localizedName(language: .english)
            )
        }
    }

    func testIndoPakSuraNamesUseReadingSpecificArabicNames() {
        let names = [
            17: "بَنِي إِسْرَائِيل",
            40: "الْمُؤْمِن",
            41: "حمٓ السَّجْدَة",
            76: "الدَّهْر",
            111: "اللَّهَب",
        ]

        for (suraNumber, name) in names {
            XCTAssertEqual(
                name,
                Quran.hafsIndoPak.suras[suraNumber - 1].localizedName(language: .arabic)
            )
        }
    }

    func testMadaniSuraNamesRemainUnchanged() {
        let names = [
            17: "Al-Isrāʾ",
            40: "Ghāfir",
            41: "Fuṣṣilat",
            76: "Al-Insān",
            111: "Al-Masad",
        ]

        for (suraNumber, name) in names {
            XCTAssertEqual(
                name,
                Quran.hafsMadani1405.suras[suraNumber - 1].localizedName(language: .english)
            )
        }
    }

    func testOtherIndoPakSuraNamesContinueUsingSurasCatalog() {
        XCTAssertEqual(
            Quran.hafsMadani1405.firstSura.localizedName(language: .english),
            Quran.hafsIndoPak.firstSura.localizedName(language: .english)
        )
    }

    func testIndoPakTranslatedSuraNamesUseReadingSpecificEnglishNames() {
        let names = [
            17: "Children of Israel",
            40: "The Believer",
            41: "Ḥā-Mīm The Prostration",
            76: "The Time",
            111: "The Flame",
        ]

        for (suraNumber, name) in names {
            XCTAssertEqual(
                name,
                Quran.hafsIndoPak.suras[suraNumber - 1].localizedTranslatedName(language: .english)
            )
        }
    }

    func testMadaniTranslatedSuraNamesRemainUnchanged() {
        let names = [
            17: "The Journey by Night",
            40: "The Forgiver",
            41: "They are explained in detail",
            76: "Man",
            111: "The Palm Fibre",
        ]

        for (suraNumber, name) in names {
            XCTAssertEqual(
                name,
                Quran.hafsMadani1405.suras[suraNumber - 1].localizedTranslatedName(language: .english)
            )
        }
    }

    func testOtherIndoPakTranslatedSuraNamesContinueUsingSurasCatalog() {
        XCTAssertEqual(
            Quran.hafsMadani1405.firstSura.localizedTranslatedName(language: .english),
            Quran.hafsIndoPak.firstSura.localizedTranslatedName(language: .english)
        )
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405

    /// Foundation wraps arguments of a right-to-left format in invisible bidi isolates.
    private func withoutBidiIsolates(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{2068}", with: "").replacingOccurrences(of: "\u{2069}", with: "")
    }
}
