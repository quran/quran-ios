//
//  SQLiteArabicTextPersistence.swift
//  Quran
//
//  Created by Hossam Ghareeb on 6/20/16.
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
import SQLite
import SQLitePersistence

private struct Columns {
    static let sura = Expression<Int>("sura")
    static let ayah = Expression<Int>("ayah")
    static let text = Expression<String>("text")
    static let offsets = Expression<String>(literal: "offsets(verses)")
}

class SQLiteArabicTextPersistence: AyahTextPersistence, ReadonlySQLitePersistence {

    private let table = Table("arabic_text")
    private let versesTable = Table("verses")

    var filePath: String { return Files.quranTextPath }

    func getAyahTextForNumber(_ number: AyahNumber) throws -> String {
        return try run { connection in
            let query = table.filter(Columns.sura == number.sura && Columns.ayah == number.ayah)
            let rows = try connection.prepare(query)

            guard let first = rows.first(where: { _ in true }) else {
                throw PersistenceError.general("Cannot find any records for ayah '\(number)'")
            }
            return first[Columns.text]
        }
    }

    func getOptionalAyahText(forNumber number: AyahNumber) throws -> String? {
        return try run { connection in
            let query = table.filter(Columns.sura == number.sura && Columns.ayah == number.ayah)
            let rows = try connection.prepare(query)

            guard let first = rows.first(where: { _ in true }) else {
                return nil
            }
            return first[Columns.text]
        }
    }

    func searchForAutcompleting(term: String) throws -> [SearchAutocompletion] {
        return try run { connection in
            return try autocomplete(term: term, connection: connection, table: versesTable)
        }
    }

    func search(for term: String) throws -> [SearchResult] {
        return try run { connection in
            return try searching(for: term, connection: connection, table: versesTable)
        }
    }
}

class SQLiteTranslationTextPersistence: AyahTextPersistence, ReadonlySQLitePersistence {
    private let table = Table("verses")

    let filePath: String

    init(filePath: String) {
        self.filePath = filePath
    }

    func getAyahTextForNumber(_ number: AyahNumber) throws -> String {
        try validateFileExists()

        return try run { connection in

            let query = table.filter(Columns.sura == number.sura && Columns.ayah == number.ayah)
            let rows = try connection.prepare(query)
            guard let first = rows.first(where: { _ in true }) else {
                throw PersistenceError.general("Cannot find any records for ayah '\(number)'")
            }
            return first[Columns.text]
        }
    }

    func getOptionalAyahText(forNumber number: AyahNumber) throws -> String? {
        try validateFileExists()

        return try run { connection in

            let query = table.filter(Columns.sura == number.sura && Columns.ayah == number.ayah)
            let rows = try connection.prepare(query)
            guard let first = rows.first(where: { _ in true }) else {
                return nil
            }
            return first[Columns.text]
        }
    }

    func searchForAutcompleting(term: String) throws -> [SearchAutocompletion] {
        try validateFileExists()
        return try run { connection in
            return try autocomplete(term: term, connection: connection, table: table)
        }
    }

    func search(for term: String) throws -> [SearchResult] {
        try validateFileExists()
        return try run { connection in
            return try searching(for: term, connection: connection, table: table)
        }
    }
}

private func searching(for term: String, connection: Connection, table: Table) throws -> [SearchResult] {
    let searchTerm: String
    let components = term.components(separatedBy: "\"")
    if components.count % 2 == 0 {
        searchTerm = term.lowercased()
    } else {
        searchTerm = components.joined(separator: "").lowercased()
    }
    let query = table
        .select(Columns.text, Columns.sura, Columns.ayah, Columns.offsets)
        .filter(Columns.text.match("\(searchTerm)"))
    let rows = try connection.prepare(query)
    return try rowsToResults(rows, term: searchTerm.lowercased())
}

private func rowsToResults(_ rows: AnySequence<Row>, term: String) throws -> [SearchResult] {
    var results: [SearchResult] = []
    for row in rows {
        let text = row[Columns.text]
        let sura = row[Columns.sura]
        let ayah = row[Columns.ayah]
        let offsets = row[Columns.offsets]

        let offsetsInt = offsets
            .components(separatedBy: " ")
            .flatMap { Int($0) }
        guard offsetsInt.count % 4 == 0 else {
            continue
        }

        var ranges: [Range<String.Index>] = []
        for index in stride(from: 0, to: offsetsInt.count, by: 4) {
            let byteOffset = offsetsInt[index + 2]
            let byteSize = offsetsInt[index + 3]

            guard let startIndex = text.byteOffsetToStringIndex(byteOffset) else {
                throw PersistenceError.general("Searching, bad start index returned")
            }

            guard let endIndex = text.byteOffsetToStringIndex(byteOffset + byteSize) else {
                throw PersistenceError.general("Searching, bad end index returned")
            }

            ranges.append(startIndex..<endIndex)
        }

        let ayahNumber = AyahNumber(sura: sura, ayah: ayah)
        let result = SearchResult(text: text, ayah: ayahNumber, page: Quran.pageForAyah(ayahNumber), highlightedRanges: ranges)
        results.append(result)
    }
    return results
}

private func autocomplete(term: String, connection: Connection, table: Table) throws -> [SearchAutocompletion] {
    let searchTerm: String
    let components = term.components(separatedBy: "\"")
    if components.count % 2 == 0 {
        searchTerm = term.lowercased()
    } else {
        searchTerm = components.joined(separator: "").lowercased()
    }
    let query = table
        .select(Columns.text)
        .filter(Columns.text.match("\(searchTerm)*"))
        .limit(100)
    let rows = try connection.prepare(query)
    return try rowsToAutocompletions(rows, term: searchTerm.lowercased())
}

private func rowsToAutocompletions(_ rows: AnySequence<Row>, term: String) throws -> [SearchAutocompletion] {
    var result: [SearchAutocompletion] = []
    var added: Set<String> = []
    for row in rows {
        let text = row[Columns.text]

        guard let range = text.range(of: term, options: .caseInsensitive, range: nil, locale: nil) else {
            continue
        }

        let substring = text.substring(from: range.lowerBound)
        guard !added.contains(substring) else {
            continue
        }
        added.insert(substring)

        let autocompletion = SearchAutocompletion(text: substring, highlightedRange: term.startIndex..<term.endIndex)
        result.append(autocompletion)
    }

    return result
}
