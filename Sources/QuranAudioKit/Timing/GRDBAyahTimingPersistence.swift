//
//  GRDBAyahTimingPersistence.swift
//
//
//  Created by Mohamed Afifi on 2023-05-22.
//

import Foundation
import GRDB
import QuranKit
import SQLitePersistence
import VLogging

struct GRDBAyahTimingPersistence: AyahTimingPersistence {
    let db: DatabaseWriter

    init(db: DatabaseWriter) {
        self.db = db
    }

    init(fileURL: URL) throws {
        self.init(db: try DatabasePool.newInstance(filePath: fileURL.path, readOnly: true))
    }

    func getVersion() async throws -> Int {
        try await db.write { db in
            let property = try GRDBProperty
                .filter(GRDBProperty.Columns.property == "version")
                .fetchOne(db)
            let version = property.flatMap { Int($0.value) }
            return version ?? 1
        }
    }

    func getOrderedTimingForSura(startAyah: QuranKit.AyahNumber) async throws -> SuraTiming {
        try await db.read { db in
            let query = GRDBTiming.filter(GRDBTiming.Columns.sura == startAyah.sura.suraNumber
                && GRDBTiming.Columns.ayah >= startAyah.ayah)
                .order(GRDBTiming.Columns.ayah)
            var timings: [AyahTiming] = []
            var endTime: Timing?
            let rows = try query.fetchAll(db)
            for row in rows {
                let ayah = row.ayah
                let time = Timing(time: row.time)
                if ayah == 999 {
                    endTime = time
                } else {
                    let verse = AyahNumber(quran: startAyah.quran, sura: row.sura, ayah: ayah)!
                    let timing = AyahTiming(ayah: verse, time: time)
                    timings.append(timing)
                }
            }
            return SuraTiming(verses: timings, endTime: endTime)
        }
    }
}

private struct GRDBTiming: Decodable, FetchableRecord, TableRecord {
    var sura: Int
    var ayah: Int
    var time: Int

    enum Columns {
        static let sura = Column(CodingKeys.sura)
        static let ayah = Column(CodingKeys.ayah)
        static let time = Column(CodingKeys.time)
    }

    static var databaseTableName: String {
        "timings"
    }
}

struct GRDBProperty: Decodable, FetchableRecord, TableRecord {
    var property: String
    var value: String

    enum Columns {
        static let property = Column("property")
        static let value = Column("value")
    }

    static var databaseTableName: String {
        "properties"
    }
}
