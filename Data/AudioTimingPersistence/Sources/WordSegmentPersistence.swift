//
//  WordSegmentPersistence.swift
//
//
//  Word-by-word recitation timings, keyed by the sura audio file's own timeline.
//

import Foundation
import GRDB
import QuranAudio
import SQLitePersistence

public struct WordSegmentPersistence {
    // MARK: Lifecycle

    public init(fileURL: URL) {
        db = DatabaseConnection(url: fileURL)
    }

    // MARK: Public

    /// A sura's word spans. A database with no `word_segments` table, or no rows for the
    /// sura, returns an empty timeline rather than an error.
    public func timeline(forSura sura: Int) async throws -> WordSegmentTimeline {
        let segments = try await db.read { db in
            guard try db.tableExists(GRDBWordSegment.databaseTableName) else {
                return [WordSegment]()
            }
            return try GRDBWordSegment
                .filter(GRDBWordSegment.Columns.sura == sura)
                .fetchAll(db)
                .map(WordSegment.init)
        }
        return WordSegmentTimeline(segments: segments)
    }

    // MARK: Internal

    let db: DatabaseConnection
}

private struct GRDBWordSegment: Decodable, FetchableRecord, TableRecord {
    enum CodingKeys: String, CodingKey {
        case sura
        case ayah
        case position
        case startMs = "start_ms"
        case endMs = "end_ms"
    }

    enum Columns {
        static let sura = Column(CodingKeys.sura)
    }

    static var databaseTableName: String {
        "word_segments"
    }

    var sura: Int
    var ayah: Int
    var position: Int
    var startMs: Int
    var endMs: Int
}

private extension WordSegment {
    init(_ record: GRDBWordSegment) {
        self.init(
            sura: record.sura,
            ayah: record.ayah,
            position: record.position,
            startMs: record.startMs,
            endMs: record.endMs
        )
    }
}
