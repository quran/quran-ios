//
//  GRDBWordFramePersistence.swift
//
//
//  Created by Mohamed Afifi on 2023-05-22.
//

import Foundation
import GRDB
import QuranGeometry
import QuranKit
import SQLitePersistence

public struct GRDBWordFramePersistence: WordFramePersistence {
    // MARK: Lifecycle

    init(db: DatabaseConnection) {
        self.db = db
    }

    public init(fileURL: URL) {
        self.init(db: DatabaseConnection(url: fileURL))
    }

    // MARK: Public

    public func wordFrameCollectionForPage(_ page: Page) async throws -> [WordFrame] {
        try await db.read { db in
            let query = GRDBGlyph.filter(GRDBGlyph.Columns.page == page.pageNumber)

            var frames = [WordFrame]()
            for glyph in try GRDBGlyph.fetchAll(db, query) {
                let frame = glyph.toWordFrame(quran: page.quran)
                frames.append(frame)
            }
            return frames
        }
    }

    public func suraHeaders(_ page: Page) async throws -> [SuraHeaderLocation] {
        try await db.read { db in
            let query = GRDBSuraHeader.filter(GRDBSuraHeader.Columns.page == page.pageNumber)
            let suraHeaders = try GRDBSuraHeader.fetchAll(db, query)
            return suraHeaders.map { $0.toSuraHeaderLocation(quran: page.quran) }
        }
    }

    public func ayahNumbers(_ page: Page) async throws -> [AyahNumberLocation] {
        try await db.read { db in
            let query = GRDBAyahMarker.filter(GRDBAyahMarker.Columns.page == page.pageNumber)
            let ayahMarkers = try GRDBAyahMarker.fetchAll(db, query)
            return ayahMarkers.map { $0.toAyahNumberLocation(quran: page.quran) }
        }
    }

    // MARK: Internal

    let db: DatabaseConnection
}

private struct GRDBGlyph: Decodable, FetchableRecord, TableRecord {
    enum CodingKeys: String, CodingKey {
        case id = "glyph_id"
        case page = "page_number"
        case sura = "sura_number"
        case ayah = "ayah_number"
        case line = "line_number"
        case position
        case minX = "min_x"
        case maxX = "max_x"
        case minY = "min_y"
        case maxY = "max_y"
    }

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let page = Column(CodingKeys.page)
        static let sura = Column(CodingKeys.sura)
        static let ayah = Column(CodingKeys.ayah)
        static let line = Column(CodingKeys.line)
        static let position = Column(CodingKeys.position)
        static let minX = Column(CodingKeys.minX)
        static let maxX = Column(CodingKeys.maxX)
        static let minY = Column(CodingKeys.minY)
        static let maxY = Column(CodingKeys.maxY)
    }

    // MARK: Internal

    static var databaseTableName: String {
        "glyphs"
    }

    var id: Int
    var page: Int
    var sura: Int
    var ayah: Int
    var line: Int
    var position: Int
    var minX: Int
    var maxX: Int
    var minY: Int
    var maxY: Int
}

extension GRDBGlyph {
    func toWordFrame(quran: Quran) -> WordFrame {
        let ayah = AyahNumber(quran: quran, sura: sura, ayah: ayah)!
        return WordFrame(
            line: line,
            word: Word(verse: ayah, wordNumber: position),
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY
        )
    }
}

private struct GRDBSuraHeader: Decodable, FetchableRecord, TableRecord {
    enum CodingKeys: String, CodingKey {
        case suraNumber = "sura_number"
        case x
        case y
        case width
        case height
        case page = "page_number"
    }

    enum Columns {
        static let suraNumber = Column(CodingKeys.suraNumber)
        static let x = Column(CodingKeys.x)
        static let y = Column(CodingKeys.y)
        static let width = Column(CodingKeys.width)
        static let height = Column(CodingKeys.height)
        static let page = Column(CodingKeys.page)
    }

    // MARK: Internal

    static var databaseTableName: String {
        "sura_headers"
    }

    var suraNumber: Int
    var x: Int
    var y: Int
    var width: Int
    var height: Int
    var page: Int
}

extension GRDBSuraHeader {
    func toSuraHeaderLocation(quran: Quran) -> SuraHeaderLocation {
        SuraHeaderLocation(
            sura: Sura(quran: quran, suraNumber: suraNumber)!,
            x: x, y: y, width: width, height: height
        )
    }
}

private struct GRDBAyahMarker: Decodable, FetchableRecord, TableRecord {
    enum CodingKeys: String, CodingKey {
        case suraNumber = "sura_number"
        case ayahNumber = "ayah_number"
        case x
        case y
        case page = "page_number"
    }

    enum Columns {
        static let suraNumber = Column(CodingKeys.suraNumber)
        static let ayahNumber = Column(CodingKeys.ayahNumber)
        static let x = Column(CodingKeys.x)
        static let y = Column(CodingKeys.y)
        static let page = Column(CodingKeys.page)
    }

    // MARK: Internal

    static var databaseTableName: String {
        "ayah_markers"
    }

    var suraNumber: Int
    var ayahNumber: Int
    var x: Int
    var y: Int
    var page: Int
}

extension GRDBAyahMarker {
    func toAyahNumberLocation(quran: Quran) -> AyahNumberLocation {
        AyahNumberLocation(
            ayah: AyahNumber(quran: quran, sura: suraNumber, ayah: ayahNumber)!,
            x: x, y: y
        )
    }
}
