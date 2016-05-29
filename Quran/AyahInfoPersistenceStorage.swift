//
//  AyahInfoPersistenceStorage.swift
//  Quran
//
//  Created by Ahmed El-Helw on 5/12/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import SQLite

struct AyahInfoPersistenceStorage: AyahInfoStorage {

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

    private var db: LazyConnectionWrapper = {
        let file = String(format: "images_\(quranImagesSize)/databases/ayahinfo_\(quranImagesSize)")
        guard let path = NSBundle.mainBundle().pathForResource(file, ofType: "db") else {
            fatalError("Unable to find ayahinfo database in resources")
        }

        return LazyConnectionWrapper(sqliteFilePath: path, readonly: true)
    }()

    func getAyahInfoForPage(page: Int) throws -> [AyahNumber : [AyahInfo]] {
        let query = glyphsTable.filter(columns.page == page)

        var result = [AyahNumber : [AyahInfo]]()
        do {
            for row in try db.connection.prepare(query) {
                let ayah = AyahNumber(sura: row[columns.sura], ayah: row[columns.ayah])
                var ayahInfoList = result[ayah] ?? []
                ayahInfoList += [ getAyahInfoFromRow(row, ayah: ayah) ]
                result[ayah] = ayahInfoList
            }
            return result
        } catch {
            throw PersistenceError.QueryError(error: error)
        }
    }

    func getAyahInfoForSuraAyah(sura: Int, ayah: Int) throws -> [AyahInfo] {
        let query = glyphsTable.filter(columns.sura == sura && columns.ayah == ayah)

        var result: [AyahInfo] = []
        let ayah = AyahNumber(sura: sura, ayah: ayah)
        do {
            for row in try db.connection.prepare(query) {
                result += [ getAyahInfoFromRow(row, ayah: ayah) ]
            }
            return result
        } catch {
            throw PersistenceError.QueryError(error: error)
        }
    }

    private func getAyahInfoFromRow(row: Row, ayah: AyahNumber) -> AyahInfo {
        return AyahInfo(page: row[columns.page],
                        line: row[columns.line],
                        ayah: ayah,
                        position: row[columns.position],
                        minX: row[columns.minX],
                        maxX: row[columns.maxX],
                        minY: row[columns.minY],
                        maxY: row[columns.maxY])
    }
}
