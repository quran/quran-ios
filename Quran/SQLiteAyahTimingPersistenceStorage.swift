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

    fileprivate struct Column {
        static let sura = Expression<Int>("sura")
        static let ayah = Expression<Int>("ayah")
        static let time = Expression<Int>("time")
    }

    fileprivate let timingsTable = Table("timings")

    func getTimingForSura(startAyah: AyahNumber, databaseFileURL: Foundation.URL) throws -> [AyahNumber: AyahTiming] {
        let db = LazyConnectionWrapper(sqliteFilePath: databaseFileURL.absoluteString, readonly: true)
        let query = timingsTable.filter(Column.sura == startAyah.sura && Column.ayah >= startAyah.ayah)
        do {
            var timings: [AyahNumber: AyahTiming] = [:]
            let rows = try db.getOpenConnection().prepare(query)
            for row in rows {
                let ayah = AyahNumber(sura: row[Column.sura], ayah: row[Column.ayah])
                let timing = AyahTiming(ayah: ayah, time: row[Column.time])
                timings[ayah] = timing
            }
            return timings
        } catch {
            Crash.recordError(error, reason: "Couldn't get timing for sura starting from '\(startAyah)")
            throw PersistenceError.queryError(error: error)
        }
    }

    func getOrderedTimingForSura(startAyah: AyahNumber, databaseFileURL: Foundation.URL) throws -> [AyahTiming] {
        let db = LazyConnectionWrapper(sqliteFilePath: databaseFileURL.absoluteString, readonly: true)
        let query = timingsTable.filter(Column.sura == startAyah.sura && Column.ayah >= startAyah.ayah).order(Column.ayah)
        do {
            var timings: [AyahTiming] = []
            let rows = try db.getOpenConnection().prepare(query)
            for row in rows {
                let ayah = AyahNumber(sura: row[Column.sura], ayah: row[Column.ayah])
                let timing = AyahTiming(ayah: ayah, time: row[Column.time])
                timings.append(timing)
            }
            return timings
        } catch {
            Crash.recordError(error, reason: "Couldn't get ordered timing for sura starting from '\(startAyah)")
            throw PersistenceError.queryError(error: error)
        }
    }
}
