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
        static let suraStr = Expression<String>("sura")
        static let ayahStr = Expression<String>("ayah")
        static let text = Expression<String>("text")
    }

    let filePath: String
    let table: Table

    private let searchTable = Table("verses")

    func textForVerse<T>(_ verse: AyahNumber, transform: (Row, Quran) throws -> T) throws -> T {
        try run { connection in
            if let text = try textForVerse(verse, connection: connection, transform: transform) {
                return text
            }
            throw PersistenceError.general("Cannot find any records for verse '\(verse)'")
        }
    }

    func textForVerses<T>(_ verses: [AyahNumber], transform: (Row, Quran) throws -> T) throws -> [AyahNumber: T] {
        try run { connection in
            var dictionary: [AyahNumber: T] = [:]
            for verse in verses {
                dictionary[verse] = try textForVerse(verse, connection: connection, transform: transform)
            }
            return dictionary
        }
    }

    private func textForVerse<T>(_ verse: AyahNumber, connection: Connection, transform: (Row, Quran) throws -> T) throws -> T? {
        let query = table
            .select(Columns.text)
            .filter((Columns.sura == verse.sura.suraNumber || Columns.suraStr == String(verse.sura.suraNumber)) &&
                (Columns.ayah == verse.ayah || Columns.ayahStr == String(verse.ayah)))
        let rows = try connection.prepare(query)
        guard let first = rows.first(where: { _ in true }) else {
            return nil
        }
        return try transform(first, verse.quran)
    }

    // MARK: - Search

    func autocomplete(term: String) throws -> [String] {
        try run { connection in
            let query = searchTable
                .select(Columns.text)
                .filter(Columns.text.match("\(term)*"))
                .limit(100)
            let rows = try connection.fetchArray(query)
            return rows.map { $0[Columns.text] }
        }
    }

    func search(for term: String, quran: Quran) throws -> [(verse: AyahNumber, text: String)] {
        try run { connection in
            let query = searchTable
                .select(Columns.text, Columns.sura, Columns.ayah)
                .filter(Columns.text.like("%\(term)%"))
            let rows = try connection.fetchArray(query)
            return rowsToResults(rows, quran: quran)
        }
    }

    private func rowsToResults(_ rows: [Row], quran: Quran) -> [(verse: AyahNumber, text: String)] {
        rows.map { row in
            let text = row[Columns.text]
            let sura = row[Columns.sura]
            let ayah = row[Columns.ayah]
            let verse = AyahNumber(quran: quran, sura: sura, ayah: ayah)!
            return (verse: verse, text: text)
        }
    }
}

private extension Connection {
    func fetchArray(_ query: QueryType) throws -> [Row] {
        let iterator = try prepareRowIterator(query)
        return (try? Array(iterator)) ?? []
    }
}
