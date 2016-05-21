//
//  SQLiteAyahTimingPersistenceStorage.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import SQLite

struct SQLiteAyahTimingPersistenceStorage: QariAyahTimingPersistenceStorage {

    private struct Column {
        static let sura = Expression<Int>("sura")
        static let ayah = Expression<Int>("ayah")
        static let time = Expression<Int>("time")
    }

    private let timingsTable = Table("timings")

    func getTimingForSura(startAyah startAyah: AyahNumber, databaseFileURL: NSURL) -> [AyahNumber: AyahTiming] {
        let db = LazyConnectionWrapper(sqliteFilePath: databaseFileURL.absoluteString, readonly: true)
        let query = timingsTable.filter(Column.sura == startAyah.sura && Column.ayah >= startAyah.ayah)
        do {
            var timings: [AyahNumber: AyahTiming] = [:]
            let rows = try db.connection.prepare(query)
            for row in rows {
                let ayah = AyahNumber(sura: row[Column.sura], ayah: row[Column.ayah])
                let timing = AyahTiming(ayah: ayah, time: row[Column.time])
                timings[ayah] = timing
            }
            return timings
        } catch {
            fatalError("Couldn't execute quary for sqlite database with error, '\(error)'")
        }
    }
}
