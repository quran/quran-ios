//
//  GeneralVerseTextPersistence.swift
//
//
//  Created by Mohamed Afifi on 2021-11-14.
//

import QuranKit
import SQLite
import SQLitePersistence

struct GeneralVerseTextPersistence: ReadonlySQLitePersistence {
    struct Columns {
        static let sura = Expression<Int>("sura")
        static let ayah = Expression<Int>("ayah")
        static let text = Expression<String>("text")
    }

    let filePath: String
    let table: Table
    let quran: Quran

    private let searchTable = Table("verses")

    func textForVerse(_ verse: AyahNumber) throws -> String {
        if let text = try textForVerseIfExists(verse) {
            return text
        }
        throw PersistenceError.general("Cannot find any records for verse '\(verse)'")
    }

    private func textForVerseIfExists(_ verse: AyahNumber) throws -> String? {
        try run { connection in
            try textForVerse(verse, connection: connection)
        }
    }

    private func textForVerse(_ verse: AyahNumber, connection: Connection) throws -> String? {
        let query = table
            .select(Columns.text)
            .filter(Columns.sura == verse.sura.suraNumber && Columns.ayah == verse.ayah)
        let rows = try connection.prepare(query)
        guard let first = rows.first(where: { _ in true }) else {
            return nil
        }
        return first[Columns.text]
    }

    func textForVerses(_ verses: [AyahNumber]) throws -> [AyahNumber: String] {
        try run { connection in
            var dictionary: [AyahNumber: String] = [:]
            for verse in verses {
                dictionary[verse] = try textForVerse(verse, connection: connection)
            }
            return dictionary
        }
    }

    // MARK: - Search

    func autocomplete(term: String) throws -> [String] {
        try run { connection in
            let query = searchTable
                .select(Columns.text)
                .filter(Columns.text.match("\(term)*"))
                .limit(100)
            let rows = try connection.prepare(query)
            return rows.map { $0[Columns.text] }
        }
    }

    func search(for term: String) throws -> [(verse: AyahNumber, text: String)] {
        try run { connection in
            let query = searchTable
                .select(Columns.text, Columns.sura, Columns.ayah)
                .filter(Columns.text.like("%\(term)%"))
            let rows = try connection.prepare(query)
            return rowsToResults(rows)
        }
    }

    private func rowsToResults(_ rows: AnySequence<Row>) -> [(verse: AyahNumber, text: String)] {
        rows.map { row in
            let text = row[Columns.text]
            let sura = row[Columns.sura]
            let ayah = row[Columns.ayah]
            let verse = AyahNumber(quran: quran, sura: sura, ayah: ayah)!
            return (verse: verse, text: text)
        }
    }
}
