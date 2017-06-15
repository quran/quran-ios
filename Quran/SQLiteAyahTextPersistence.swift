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
    static let snippet = Expression<String>(literal: "snippet(verses, '<b>', '</b>', '...', -1, 64)")
}

private enum WordType: String {
    case word
    case end
    case pause
    case sajdah
    case rubHizb = "rub-el-hizb"
}

class SQLiteArabicTextPersistence: AyahTextPersistence, ReadonlySQLitePersistence {

    private let table = Table("words")
    private let versesTable = Table("verses")
    private let wordType = Expression<String>("word_type")
    private let wordPosition = Expression<Int>("word_position")
    private let textMadani = Expression<String?>("text_madani")

    var filePath: String { return Files.wordsTextPath }

    func getAyahTextForNumber(_ number: AyahNumber) throws -> String {
        guard let text = try getOptionalAyahText(forNumber: number) else {
            throw PersistenceError.general("Cannot find any records for ayah '\(number)'")
        }
        return text
    }

    func getOptionalAyahText(forNumber number: AyahNumber) throws -> String? {
        return try run { connection in
            let query = table
                .select(textMadani)
                .filter(Columns.sura == number.sura && Columns.ayah == number.ayah && wordType != WordType.end.rawValue)
                .order(wordPosition)
            let rows = try connection.prepare(query)
            return rowsToAyahText(rows)
        }
    }

    private func rowsToAyahText(_ rows: AnySequence<Row>) -> String? {
        let words = rows.flatMap { $0[textMadani] }
        guard !words.isEmpty else {
            return nil
        }
        return words.joined(separator: " ")
    }

    func autocomplete(term: String) throws -> [SearchAutocompletion] {
        return try run { connection in
            return try _autocomplete(term: term, connection: connection, table: versesTable)
        }
    }

    func search(for term: String) throws -> [SearchResult] {
        return try run { connection in
            return try _search(for: term, connection: connection, table: versesTable)
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

    func autocomplete(term: String) throws -> [SearchAutocompletion] {
        try validateFileExists()
        return try run { connection in
            return try _autocomplete(term: term, connection: connection, table: table)
        }
    }

    func search(for term: String) throws -> [SearchResult] {
        try validateFileExists()
        return try run { connection in
            return try _search(for: term, connection: connection, table: table)
        }
    }
}

private func _search(for term: String, connection: Connection, table: Table) throws -> [SearchResult] {
    CLog("Search for:", term)
    let searchTerm = cleanup(term: term)
    let query = table
        .select(Columns.snippet, Columns.sura, Columns.ayah)
        .filter(Columns.text.match("\(searchTerm)"))
        .limit(300)
    let rows = try connection.prepare(query)
    return try rowsToResults(rows, term: searchTerm)
}

private func rowsToResults(_ rows: AnySequence<Row>, term: String) throws -> [SearchResult] {
    var results: [SearchResult] = []
    for row in rows {
        let text = row[Columns.snippet]
        let sura = row[Columns.sura]
        let ayah = row[Columns.ayah]
        let ayahNumber = AyahNumber(sura: sura, ayah: ayah)
        let result = SearchResult(text: text, ayah: ayahNumber, page: Quran.pageForAyah(ayahNumber))
        results.append(result)
    }
    return results
}

private func _autocomplete(term: String, connection: Connection, table: Table) throws -> [SearchAutocompletion] {
    CLog("Autocompleting term:", term)
    let searchTerm = cleanup(term: term)
    let query = table
        .select(Columns.text)
        .filter(Columns.text.match("\(searchTerm)*"))
        .limit(100)
    let rows = try connection.prepare(query)
    return try rowsToAutocompletions(rows, term: searchTerm)
}

private func rowsToAutocompletions(_ rows: AnySequence<Row>, term: String) throws -> [SearchAutocompletion] {
    var result: [SearchAutocompletion] = []
    var added: Set<String> = []
    for row in rows {
        let text = row[Columns.text]

        guard let range = text.range(of: term, options: .caseInsensitive, range: nil, locale: nil) else {
            continue
        }

        var substring = text.substring(from: range.lowerBound)
        if substring.characters.count > 100 {
            if let endIndex = substring.index(substring.startIndex, offsetBy: 100, limitedBy: substring.endIndex) {
                substring = substring.substring(to: endIndex)
            }
        }
        guard !added.contains(substring) else {
            continue
        }
        added.insert(substring)

        let autocompletion = SearchAutocompletion(text: substring, highlightedRange: term.startIndex..<term.endIndex)
        result.append(autocompletion)
    }

    return result
}

private func cleanup(term: String) -> String {
    let legalTokens = CharacterSet.whitespaces.union(.alphanumerics)
    var cleanedTerm = term.components(separatedBy: legalTokens.inverted).joined(separator: "")
    if let upTo = cleanedTerm.index(cleanedTerm.startIndex, offsetBy: 1_000, limitedBy: cleanedTerm.endIndex) {
        cleanedTerm = cleanedTerm.substring(to: upTo)
    }
    return cleanedTerm.lowercased()
}
