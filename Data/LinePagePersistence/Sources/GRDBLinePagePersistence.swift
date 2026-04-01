//
//  GRDBLinePagePersistence.swift
//
//
//  Created by Mohamed Afifi on 2026-03-28.
//

import Foundation
import GRDB
import QuranKit
import SQLitePersistence

public struct GRDBLinePagePersistence: LinePagePersistence {
    // MARK: Lifecycle

    init(db: DatabaseConnection) {
        self.db = db
    }

    public init(fileURL: URL) {
        self.init(db: DatabaseConnection(url: fileURL))
    }

    // MARK: Public

    public func highlightSpans(_ page: Page) async throws -> [LinePageHighlightSpan] {
        try await db.read { db in
            let query = GRDBAyahHighlight
                .filter(GRDBAyahHighlight.Columns.page == page.pageNumber)
                .order(
                    GRDBAyahHighlight.Columns.sura,
                    GRDBAyahHighlight.Columns.ayah,
                    GRDBAyahHighlight.Columns.line,
                    GRDBAyahHighlight.Columns.left,
                    GRDBAyahHighlight.Columns.right
                )
            return try GRDBAyahHighlight.fetchAll(db, query).map { $0.toHighlightSpan(quran: page.quran) }
        }
    }

    public func ayahMarkers(_ page: Page) async throws -> [LinePageAyahMarker] {
        try await db.read { db in
            let query = GRDBAyahMarker
                .filter(GRDBAyahMarker.Columns.page == page.pageNumber)
                .order(
                    GRDBAyahMarker.Columns.sura,
                    GRDBAyahMarker.Columns.ayah,
                    GRDBAyahMarker.Columns.line
                )
            return try GRDBAyahMarker.fetchAll(db, query).map { $0.toAyahMarker(quran: page.quran) }
        }
    }

    public func suraHeaders(_ page: Page) async throws -> [LinePageSuraHeader] {
        try await db.read { db in
            let query = GRDBSuraHeader
                .filter(GRDBSuraHeader.Columns.page == page.pageNumber)
                .order(
                    GRDBSuraHeader.Columns.sura,
                    GRDBSuraHeader.Columns.line
                )
            return try GRDBSuraHeader.fetchAll(db, query).map { $0.toSuraHeader(quran: page.quran) }
        }
    }

    // MARK: Internal

    let db: DatabaseConnection
}

private struct GRDBAyahHighlight: Decodable, FetchableRecord, TableRecord {
    enum CodingKeys: String, CodingKey {
        case page
        case sura
        case ayah
        case line
        case left
        case right
    }

    enum Columns {
        static let page = Column(CodingKeys.page)
        static let sura = Column(CodingKeys.sura)
        static let ayah = Column(CodingKeys.ayah)
        static let line = Column(CodingKeys.line)
        static let left = Column(CodingKeys.left)
        static let right = Column(CodingKeys.right)
    }

    static var databaseTableName: String {
        "ayah_highlights"
    }

    var page: Int
    var sura: Int
    var ayah: Int
    var line: Int
    var left: Double
    var right: Double
}

private extension GRDBAyahHighlight {
    func toHighlightSpan(quran: Quran) -> LinePageHighlightSpan {
        let ayah = AyahNumber(quran: quran, sura: sura, ayah: ayah)!
        return LinePageHighlightSpan(ayah: ayah, line: line, left: left, right: right)
    }
}

private struct GRDBAyahMarker: Decodable, FetchableRecord, TableRecord {
    enum CodingKeys: String, CodingKey {
        case page
        case sura
        case ayah
        case line
        case centerX = "center_x"
        case centerY = "center_y"
        case codePoint = "code_point"
    }

    enum Columns {
        static let page = Column(CodingKeys.page)
        static let sura = Column(CodingKeys.sura)
        static let ayah = Column(CodingKeys.ayah)
        static let line = Column(CodingKeys.line)
        static let centerX = Column(CodingKeys.centerX)
        static let centerY = Column(CodingKeys.centerY)
        static let codePoint = Column(CodingKeys.codePoint)
    }

    static var databaseTableName: String {
        "ayah_markers"
    }

    var page: Int
    var sura: Int
    var ayah: Int
    var line: Int
    var centerX: Double
    var centerY: Double
    var codePoint: String
}

private extension GRDBAyahMarker {
    func toAyahMarker(quran: Quran) -> LinePageAyahMarker {
        let ayah = AyahNumber(quran: quran, sura: sura, ayah: ayah)!
        return LinePageAyahMarker(
            ayah: ayah,
            line: line,
            centerX: centerX,
            centerY: centerY,
            codePoint: codePoint
        )
    }
}

private struct GRDBSuraHeader: Decodable, FetchableRecord, TableRecord {
    enum CodingKeys: String, CodingKey {
        case page
        case sura
        case line
        case centerX = "center_x"
        case centerY = "center_y"
    }

    enum Columns {
        static let page = Column(CodingKeys.page)
        static let sura = Column(CodingKeys.sura)
        static let line = Column(CodingKeys.line)
        static let centerX = Column(CodingKeys.centerX)
        static let centerY = Column(CodingKeys.centerY)
    }

    static var databaseTableName: String {
        "sura_headers"
    }

    var page: Int
    var sura: Int
    var line: Int
    var centerX: Double
    var centerY: Double
}

private extension GRDBSuraHeader {
    func toSuraHeader(quran: Quran) -> LinePageSuraHeader {
        let sura = Sura(quran: quran, suraNumber: sura)!
        return LinePageSuraHeader(sura: sura, line: line, centerX: centerX, centerY: centerY)
    }
}
