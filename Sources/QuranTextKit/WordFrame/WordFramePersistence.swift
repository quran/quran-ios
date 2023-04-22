//
//  WordFramePersistence.swift
//  Quran
//
//  Created by Ahmed El-Helw on 5/12/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation
import QuranKit
import SQLite
import SQLitePersistence

struct WordFramePersistence: ReadonlySQLitePersistence {
    private struct Columns {
        let id = Expression<Int>("glyph_id")
        let page = Expression<Int>("page_number")
        let sura = Expression<Int>("sura_number")
        let ayah = Expression<Int>("ayah_number")
        let line = Expression<Int>("line_number")
        let position = Expression<Int>("position")
        let minX = Expression<Int>("min_x")
        let maxX = Expression<Int>("max_x")
        let minY = Expression<Int>("min_y")
        let maxY = Expression<Int>("max_y")
    }

    private let glyphsTable = Table("glyphs")
    private let columns = Columns()

    let filePath: String

    init(fileURL: URL) {
        filePath = fileURL.path
    }

    // MARK: - glyphs

    func wordFrameCollectionForPage(_ page: Page) throws -> WordFrameCollection {
        try run { connection in
            let query = glyphsTable.filter(columns.page == page.pageNumber)

            var result = [AyahNumber: [WordFrame]]()
            for row in try connection.prepare(query) {
                let ayah = AyahNumber(quran: page.quran, sura: row[columns.sura], ayah: row[columns.ayah])!
                var mutableFrames = result[ayah] ?? []
                mutableFrames += [wordFrameFromRow(row, ayah: ayah)]
                result[ayah] = mutableFrames
            }
            return WordFrameCollection(frames: result)
        }
    }

    private func wordFrameFromRow(_ row: Row, ayah: AyahNumber) -> WordFrame {
        WordFrame(
            line: row[columns.line],
            word: Word(verse: ayah, wordNumber: row[columns.position]),
            minX: row[columns.minX],
            maxX: row[columns.maxX],
            minY: row[columns.minY],
            maxY: row[columns.maxY]
        )
    }

    // MARK: - Sura header

    func suraHeaders(_ page: Page) throws -> [SuraHeaderLocation] {
        let suraHeadersTable = Table("sura_headers")
        struct SuraHeaderColumns {
            static let suraNumber = Expression<Int>("sura_number")
            static let x = Expression<Int>("x")
            static let y = Expression<Int>("y")
            static let width = Expression<Int>("width")
            static let height = Expression<Int>("height")
            static let page = Expression<Int>("page_number")
        }

        return try run { connection in
            let query = suraHeadersTable.filter(SuraHeaderColumns.page == page.pageNumber)
            let rows = try connection.prepare(query)
            return rows.map { row in
                SuraHeaderLocation(sura: Sura(quran: page.quran, suraNumber: row[SuraHeaderColumns.suraNumber])!,
                                   x: row[SuraHeaderColumns.x],
                                   y: row[SuraHeaderColumns.y],
                                   width: row[SuraHeaderColumns.width],
                                   height: row[SuraHeaderColumns.height])
            }
        }
    }

    func ayahNumbers(_ page: Page) throws -> [AyahNumberLocation] {
        let ayahMarkersTable = Table("ayah_markers")
        struct AyahMarkerColumns {
            static let suraNumber = Expression<Int>("sura_number")
            static let ayahNumber = Expression<Int>("ayah_number")
            static let x = Expression<Int>("x")
            static let y = Expression<Int>("y")
            static let page = Expression<Int>("page_number")
        }

        return try run { connection in
            let query = ayahMarkersTable.filter(AyahMarkerColumns.page == page.pageNumber)
            let rows = try connection.prepare(query)
            return rows.map { row in
                AyahNumberLocation(ayah: AyahNumber(quran: page.quran,
                                                    sura: row[AyahMarkerColumns.suraNumber],
                                                    ayah: row[AyahMarkerColumns.ayahNumber])!,
                                   x: row[AyahMarkerColumns.x],
                                   y: row[AyahMarkerColumns.y])
            }
        }
    }
}
