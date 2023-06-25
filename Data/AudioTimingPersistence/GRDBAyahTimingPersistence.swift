//
//  GRDBAyahTimingPersistence.swift
//
//
//  Created by Mohamed Afifi on 2023-05-22.
//

import Foundation
import GRDB
import QuranAudio
import QuranKit
import SQLitePersistence
import VLogging

public struct GRDBAyahTimingPersistence: AyahTimingPersistence {
    // MARK: Lifecycle

    init(db: DatabaseConnection) {
        self.db = db
    }

    public init(fileURL: URL) {
        self.init(db: DatabaseConnection(url: fileURL))
    }

    // MARK: Public

    public func getVersion() async throws -> Int {
        try await db.read { db in
            let property = try GRDBProperty
                .filter(GRDBProperty.Columns.property == "version")
                .fetchOne(db)
            let version = property.flatMap { Int($0.value) }
            return version ?? 1
        }
    }

    public func getOrderedTimingForSura(startAyah: QuranKit.AyahNumber) async throws -> SuraTiming {
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

    // MARK: Internal

    let db: DatabaseConnection
}

private struct GRDBTiming: Decodable, FetchableRecord, TableRecord {
    enum Columns {
        static let sura = Column(CodingKeys.sura)
        static let ayah = Column(CodingKeys.ayah)
        static let time = Column(CodingKeys.time)
    }

    static var databaseTableName: String {
        "timings"
    }

    var sura: Int
    var ayah: Int
    var time: Int
}

private struct GRDBProperty: Decodable, FetchableRecord, TableRecord {
    enum Columns {
        static let property = Column(CodingKeys.property)
        static let value = Column(CodingKeys.value)
    }

    static var databaseTableName: String {
        "properties"
    }

    var property: String
    var value: String
}
