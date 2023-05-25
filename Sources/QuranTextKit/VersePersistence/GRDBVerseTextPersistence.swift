//
//  GRDBVerseTextPersistence.swift
//
//
//  Created by Mohamed Afifi on 2023-05-23.
//

import Foundation
import GRDB
import QuranKit
import SQLitePersistence

struct GRDBQuranVerseTextPersistence: VerseTextPersistence {
    enum Mode {
        case arabic
        case share

        var tabelName: String {
            switch self {
            case .arabic:
                return "arabic_text"
            case .share:
                return "share_text"
            }
        }
    }

    private let persistence: GRDBVerseTextPersistence

    init(fileURL: URL) {
        self.init(mode: .arabic, fileURL: fileURL)
    }

    init(mode: Mode, fileURL: URL) {
        persistence = GRDBVerseTextPersistence(fileURL: fileURL, textTable: mode.tabelName)
    }

    func textForVerses(_ verses: [AyahNumber]) async throws -> [AyahNumber: String] {
        try await persistence.textForVerses(verses, transform: textFromRow)
    }

    func textForVerse(_ verse: AyahNumber) async throws -> String {
        try await persistence.textForVerse(verse, transform: textFromRow)
    }

    func autocomplete(term: String) async throws -> [String] {
        try await persistence.autocomplete(term: term)
    }

    func search(for term: String, quran: Quran) async throws -> [(verse: AyahNumber, text: String)] {
        try await persistence.search(for: term, quran: quran)
    }

    private func textFromRow(_ row: Row, quran: Quran) -> String {
        row["text"]
    }
}

struct GRDBTranslationVerseTextPersistence: TranslationVerseTextPersistence {
    private let fileURL: URL
    private let persistence: GRDBVerseTextPersistence

    init(fileURL: URL) {
        self.fileURL = fileURL
        // TODO: shouldn't crash if file doesn't exist
        persistence = GRDBVerseTextPersistence(fileURL: fileURL, textTable: "verses")
    }

    func textForVerses(_ verses: [AyahNumber]) async throws -> [AyahNumber: RawTranslationText] {
        try await persistence.textForVerses(verses, transform: textFromRow)
    }

    func textForVerse(_ verse: AyahNumber) async throws -> RawTranslationText {
        try await persistence.textForVerse(verse, transform: textFromRow)
    }

    func autocomplete(term: String) async throws -> [String] {
        try await persistence.autocomplete(term: term)
    }

    func search(for term: String, quran: Quran) async throws -> [(verse: AyahNumber, text: String)] {
        try await persistence.search(for: term, quran: quran)
    }

    private func textFromRow(_ row: Row, quran: Quran) throws -> RawTranslationText {
        let value = row["text"]
        if let stringText = value as? String {
            // if the data is an Integer but saved as String, try to see if it's a valid verseId
            if let verseId = Int(stringText), verseId > 0 && verseId <= quran.verses.count {
                return referenceVerse(verseId, quran: quran)
            } else {
                return .string(stringText)
            }
        } else if let verseId = value as? Int {
            return referenceVerse(verseId, quran: quran)
        }
        throw PersistenceError.general("Text for verse is neither Int nor String. File: \(fileURL.lastPathComponent)")
    }

    private func referenceVerse(_ verseId: Int, quran: Quran) -> RawTranslationText {
        // VerseId saved is an index in the quran.verses starts with 1
        let verse = quran.verses[verseId - 1]
        return .reference(verse)
    }
}

// MARK: - Helper

private struct GRDBVerseTextPersistence {
    let db: DatabaseWriter

    private let textTable: String
    private let searchTable = "verses"

    init(db: DatabaseWriter, textTable: String) {
        self.db = db
        self.textTable = textTable
    }

    init(fileURL: URL, textTable: String) {
        self.init(db: DatabasePool.unsafeNewInstance(filePath: fileURL.path, readOnly: true), textTable: textTable)
    }

    func textForVerse<T>(_ verse: AyahNumber, transform: @escaping (Row, Quran) throws -> T) async throws -> T {
        try await db.read { db in
            if let text = try textForVerse(using: db, verse: verse, transform: transform) {
                return text
            }
            throw PersistenceError.general("Cannot find any records for verse '\(verse)'")
        }
    }

    func textForVerses<T>(
        _ verses: [AyahNumber],
        transform: @escaping (Row, Quran) throws -> T
    ) async throws -> [AyahNumber: T] {
        try await db.read { db in
            var dictionary: [AyahNumber: T] = [:]
            for verse in verses {
                dictionary[verse] = try textForVerse(using: db, verse: verse, transform: transform)
            }
            return dictionary
        }
    }

    private func textForVerse<T>(
        using db: Database,
        verse: AyahNumber,
        transform: @escaping (Row, Quran) throws -> T
    ) throws -> T? {
        // Try to search using integer and string ayah/sura.
        // Needed by some translation sqlite files.
        let request = SQLRequest<Row>("""
        SELECT text
        FROM \(sql: textTable)
        WHERE (ayah = \(verse.ayah) OR ayah = \(verse.ayah.description))
          AND (sura = \(verse.sura.suraNumber) OR sura = \(verse.sura.suraNumber.description))
        """)

        guard let row = try request.fetchOne(db) else {
            return nil
        }

        return try transform(row, verse.quran)
    }

    // MARK: - Search

    func autocomplete(term: String) async throws -> [String] {
        try await db.read { db in
            let request = SQLRequest<String>("""
            SELECT text
            FROM \(sql: searchTable)
            WHERE text match \(term) || '*'
            LIMIT 100
            """)
            let rows = try request.fetchAll(db)
            return rows
        }
    }

    func search(for term: String, quran: Quran) async throws -> [(verse: AyahNumber, text: String)] {
        try await db.read { db in
            // TODO: Use match for FTS.
            let request = SQLRequest<Row>("""
            SELECT text, sura, ayah
            FROM \(sql: searchTable)
            WHERE text like '%' || \(term) || '%'
            """)
            let rows = try request.fetchAll(db)
            return rowsToResults(rows, quran: quran)
        }
    }

    private func rowsToResults(_ rows: [Row], quran: Quran) -> [(verse: AyahNumber, text: String)] {
        rows.map { row in
            let text: String = row["text"]
            let sura: Int = row["sura"]
            let ayah: Int = row["ayah"]
            let verse = AyahNumber(quran: quran, sura: sura, ayah: ayah)!
            return (verse: verse, text: text)
        }
    }
}
