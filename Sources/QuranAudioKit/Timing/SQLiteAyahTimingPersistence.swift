//
//  SQLiteAyahTimingPersistence.swift
//  
//
//  Created by Mohamed Afifi on 2023-05-22.
//

import Crashing
import Foundation
import QuranKit
import SQLite
import SQLitePersistence

struct SQLiteAyahTimingPersistence: AyahTimingPersistence, ReadonlySQLitePersistence {
    private struct Column {
        static let sura = Expression<Int>("sura")
        static let ayah = Expression<Int>("ayah")
        static let time = Expression<Int>("time")
    }

    private let timingsTable = Table("timings")

    private struct Properties {
        static let table = Table("properties")
        static let property = Expression<String>("property")
        static let value = Expression<String>("value")
    }

    let filePath: String

    init(filePath: URL) {
        self.filePath = filePath.absoluteString
    }

    func getVersion() async throws -> Int {
        try validateFileExists()
        return try run { connection in
            let query = Properties.table
                .filter(Properties.property == "version")
                .select(Properties.value)

            let row = try connection.pluck(query)
            let version = row?[Properties.value]
            return Int(version ?? "1") ?? 1
        }
    }

    func getOrderedTimingForSura(startAyah: AyahNumber) async throws -> SuraTiming {
        try validateFileExists()

        return try run { connection in
            let query = timingsTable.filter(Column.sura == startAyah.sura.suraNumber && Column.ayah >= startAyah.ayah).order(Column.ayah)
            do {
                var timings: [AyahTiming] = []
                var endTime: Timing?
                let rows = try connection.prepare(query)
                for row in rows {
                    let ayah = row[Column.ayah]
                    let time = Timing(time: row[Column.time])
                    if ayah == 999 {
                        endTime = time
                    } else {
                        let verse = AyahNumber(quran: startAyah.quran, sura: row[Column.sura], ayah: ayah)!
                        let timing = AyahTiming(ayah: verse, time: time)
                        timings.append(timing)
                    }
                }
                return SuraTiming(verses: timings, endTime: endTime)
            } catch {
                crasher.recordError(error, reason: "Couldn't get ordered timing for sura starting from '\(startAyah)")
                throw PersistenceError.query(error)
            }
        }
    }
}
