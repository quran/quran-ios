//
//  SQLiteAyahTimingPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
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

import Crashing
import Foundation
import QuranKit
import SQLite
import SQLitePersistence

protocol AyahTimingPersistence {
    func getOrderedTimingForSura(startAyah: AyahNumber) throws -> [AyahTiming]
}

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

    func getVersion() throws -> Int {
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

    func getOrderedTimingForSura(startAyah: AyahNumber) throws -> [AyahTiming] {
        try validateFileExists()

        return try run { connection in
            let query = timingsTable.filter(Column.sura == startAyah.sura.suraNumber && Column.ayah >= startAyah.ayah).order(Column.ayah)
            do {
                var timings: [AyahTiming] = []
                let rows = try connection.prepare(query)
                for row in rows {
                    let ayah = AyahNumber(quran: startAyah.quran, sura: row[Column.sura], ayah: row[Column.ayah])!
                    let timing = AyahTiming(ayah: ayah, time: row[Column.time])
                    timings.append(timing)
                }
                return timings
            } catch {
                crasher.recordError(error, reason: "Couldn't get ordered timing for sura starting from '\(startAyah)")
                throw PersistenceError.query(error)
            }
        }
    }
}
