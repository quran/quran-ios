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

private enum WordType: String {
    case word
    case end
    case pause
    case sajdah
    case rubHizb = "rub-el-hizb"
}

class WordByWordIntegrationTests: XCTestCase {

    func testWordsAnyAyahInfoDatabasesMatchingPositionsCount() {
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
}
