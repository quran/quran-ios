//
//  WordByWordIntegrationTests.swift
//  Quran
//
//  Created by Mohamed Afifi on 6/15/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import XCTest
@testable import Quran
import SQLite
import SQLitePersistence
import QuranFoundation

private struct Words {
    static let table = Table("words")
    struct Columns {
        static let sura = Expression<Int>("sura")
        static let ayah = Expression<Int>("ayah")
        static let wordType = Expression<String>("word_type")
        static let wordPosition = Expression<Int>("word_position")
        static let textMadani = Expression<String?>("text_madani")
    }
}

private struct Glyphs {
    struct Columns {
        static let id = Expression<Int>("glyph_id")
        static let page = Expression<Int>("page_number")
        static let sura = Expression<Int>("sura_number")
        static let ayah = Expression<Int>("ayah_number")
        static let line = Expression<Int>("line_number")
        static let position = Expression<Int>("position")
        static let minX = Expression<Int>("min_x")
        static let maxX = Expression<Int>("max_x")
        static let minY = Expression<Int>("min_y")
        static let maxY = Expression<Int>("max_y")
    }
    
    static let table = Table("glyphs")
}

private struct QuranAr {
    static let table = Table("arabic_text")
    struct Columns {
        static let sura = Expression<Int>("sura")
        static let ayah = Expression<Int>("ayah")
        static let text = Expression<String>("text")
    }
}

private enum WordType: String {
    case word
    case end
    case pause
    case sajdah
    case rubHizb = "rub-el-hizb"
}

class WordByWordIntegrationTests: XCTestCase {

    func testWordsAndAyahInfoDatabasesMatchingPositionsCount() {
        expectNotToThrow {
            let wordsConnection = try Connection(Files.wordsTextPath, readonly: true)
            let wordsQuery = Words.table.select(Words.Columns.sura,
                                                Words.Columns.ayah,
                                                Words.Columns.wordPosition.count)
            let wordsRows = try wordsConnection.prepare(wordsQuery)
            var wordsAyahs: [AyahNumber: Int] = [:]
            for row in wordsRows {
                let ayah = row[Words.Columns.ayah]
                let sura = row[Words.Columns.sura]
                let count = row[Words.Columns.wordPosition.count]
                wordsAyahs[AyahNumber(sura: sura, ayah: ayah)] = count
            }

            let ayahInfoConnection = try Connection(Files.ayahInfoPath, readonly: true)
            let ayahInfoQuery = Glyphs.table.select(Glyphs.Columns.sura,
                                                    Glyphs.Columns.ayah,
                                                    Glyphs.Columns.position.count)
            let ayahInfoRows = try ayahInfoConnection.prepare(ayahInfoQuery)
            var ayahInfoAyahs: [AyahNumber: Int] = [:]
            for row in ayahInfoRows {
                let ayah = row[Glyphs.Columns.ayah]
                let sura = row[Glyphs.Columns.sura]
                let count = row[Glyphs.Columns.position.count]
                ayahInfoAyahs[AyahNumber(sura: sura, ayah: ayah)] = count
            }

            XCTAssertEqual(wordsAyahs.count, ayahInfoAyahs.count)
            for (ayah, count) in wordsAyahs {
                XCTAssertEqual(count, ayahInfoAyahs[ayah], "Position count mismatch in ayah: \(ayah)")
            }
        }
    }

    func testWordsTextMadaniMatchesQuranText() {
        let quarterStart = "۞ " // Hizb start
        expectNotToThrow {
            let persistence = SQLiteArabicTextPersistence()
            let quranConnection = try Connection(quranArPath, readonly: true)
            var count = 0
            for sura in Quran.QuranSurasRange {
                for ayah in 1...Quran.numberOfAyahsForSura(sura) {
                    let ayahNumber = AyahNumber(sura: sura, ayah: ayah)
                    let quranQuery: ScalarQuery = QuranAr.table
                        .filter(QuranAr.Columns.sura == sura && QuranAr.Columns.ayah == ayah)
                        .select(QuranAr.Columns.text)

                    var quranArText: String = try quranConnection.scalar(quranQuery)
                    if ayah == 1 {
                        quranArText = quranArText.replacingOccurrences(of: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ", with: "")
                    }
                    var wordsText = try persistence.getAyahTextForNumber(ayahNumber)
                    if wordsText.starts(with: quarterStart) {
                        wordsText = String(wordsText[quarterStart.endIndex...])
                    }
                    if quranArText != wordsText {
                        count += 1
                        print(ayahNumber.description, quranArText.lengthOfBytes(using: .utf8), wordsText.lengthOfBytes(using: .utf8))
                        print(quranArText)
                        print(wordsText)
                        print()
                        print()
                    }
                }
            }
            XCTAssertEqual(0, count, "Expected 0 errors. Consult to previous output for details of mistmatches")
            print("Total of \(count) errors!")
        }
    }

    private var quranArPath: String {
        let testBundle = Bundle(for: type(of: self))
        return testBundle.path(forResource: "quran.ar", ofType: "db")!
    }
}
