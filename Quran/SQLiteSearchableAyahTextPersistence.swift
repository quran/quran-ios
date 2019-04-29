//
//  SQLiteSearchableAyahTextPersistence.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/21/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import SQLite
import SQLitePersistence

private struct Database {
    static let table = Table("verses")
    struct Columns {
        static let sura = Expression<Int>("sura")
        static let ayah = Expression<Int>("ayah")
        static let text = Expression<String>("text")
        static let snippet = Expression<String>(literal: "snippet(verses, '<b>', '<b>', '...', -1, 64)")
    }
}

class SQLiteSearchableAyahTextPersistence: ReadonlySQLitePersistence, SearchableAyahTextPersistence {

    let filePath: String
    let regex = "[\u{0627}\u{0623}\u{0621}\u{062a}\u{0629}\u{0647}\u{0649}]"
    let replacements: [Character: String] = [
        // given: ا
        // match: آأإاﻯ
        "\u{0627}" : "\u{0622}\u{0623}\u{0625}\u{0627}\u{0649}",

        // given: ﺃ
        // match: ﺃﺀﺆﺋ
        "\u{0623}" : "\u{0621}\u{0623}\u{0624}\u{0626}",

        // given: ﺀ
        // match: ﺀﺃﺆ
        "\u{0621}" : "\u{0621}\u{0623}\u{0624}\u{0626}",

        // given: ﺕ
        // match: ﺕﺓ
        "\u{062a}" : "\u{062a}\u{0629}",

        // given: ﺓ
        // match: ﺓتﻫ
        "\u{0629}" : "\u{0629}\u{062a}\u{0647}",

        // given: ه
        // match: ةه
        "\u{0647}" : "\u{0647}\u{0629}",

        // given: ﻯ
        // match: ﻯي
        "\u{0649}" : "\u{0649}\u{064a}"
    ]

    init(filePath: String) {
        self.filePath = filePath
    }

    // MARK: - Search

    func search(for term: String) throws -> [SearchResult] {
        try validateFileExists()
        return try run { connection in
            return try search(for: term, connection: connection)
        }
    }

    private func search(for term: String, connection: Connection) throws -> [SearchResult] {
        CLog("Search for:", term)
        let searchTerm = cleanup(term: term)
        let arabicSearchTerm = searchTerm.replacingOccurrences(of: regex,
                                                               with: "_",
                                                               options: .regularExpression)
        let pattern = generateRegexPattern(term: term)
        let query = Database.table
            .select(Database.Columns.text, Database.Columns.sura, Database.Columns.ayah)
            .filter(Database.Columns.text.like("%\(arabicSearchTerm)%"))
        let rows = try connection.prepare(query)
        return try rowsToResults(rows, term: searchTerm, regexPattern: pattern)
    }

    private func rowsToResults(_ rows: AnySequence<Row>,
                               term: String,
                               regexPattern: String) throws -> [SearchResult] {
        var results: [SearchResult] = []
        for row in rows {
            let text = row[Database.Columns.text]
            if text.range(of: regexPattern, options: .regularExpression) == nil {
                continue
            }
            let highlightedText = highlightResult(text: text, regexPattern: regexPattern)
            let sura = row[Database.Columns.sura]
            let ayah = row[Database.Columns.ayah]
            let ayahNumber = AyahNumber(sura: sura, ayah: ayah)
            let result = SearchResult(text: highlightedText,
                                      ayah: ayahNumber,
                                      page: Quran.pageForAyah(ayahNumber))
            results.append(result)
        }
        return results
    }

    // MARK: - Autocomplete

    func autocomplete(term: String) throws -> [SearchAutocompletion] {
        try validateFileExists()
        return try run { connection in
            return try autocomplete(term: term, connection: connection)
        }
    }

    private func autocomplete(term: String, connection: Connection) throws -> [SearchAutocompletion] {
        CLog("Autocompleting term:", term)
        let searchTerm = cleanup(term: term)
        let query = Database.table
            .select(Database.Columns.text)
            .filter(Database.Columns.text.match("\(searchTerm)*"))
            .limit(100)
        let rows = try connection.prepare(query)
        return try rowsToAutocompletions(rows, term: searchTerm)
    }

    private func rowsToAutocompletions(_ rows: AnySequence<Row>, term: String) throws -> [SearchAutocompletion] {
        return createAutocompletions(for: rows.map { $0[Database.Columns.text] }, term: term, shouldVerify: true)
    }

    func createAutocompletions(for textArray: [String], term: String, shouldVerify: Bool) -> [SearchAutocompletion] {
        var result: [SearchAutocompletion] = []
        var added: Set<String> = []
        for text in textArray {

            let suffixes = text.caseInsensitiveComponents(separatedBy: term)
            for suffixIndex in 1..<suffixes.count {
                let suffix = suffixes[suffixIndex]
                let suffixWords = (suffix.components(separatedBy: " ")).prefix(5)
                let trimmedSuffix = suffixWords.joined(separator: " ")
                if shouldVerify && trimmedSuffix.rangeOfCharacter(from: CharacterSet.whitespaces.union(.alphanumerics).inverted) != nil {
                    continue
                }
                let subrow = term + trimmedSuffix
                if !added.contains(subrow) {
                    added.insert(subrow)
                    let autocompletion = SearchAutocompletion(text: subrow, highlightedRange: term.startIndex..<term.endIndex)
                    result.append(autocompletion)
                }
            }
        }

        return result
    }

    // MARK: - Private

    private func cleanup(term: String) -> String {
        let legalTokens = CharacterSet.whitespaces.union(.alphanumerics)
        var cleanedTerm = term.trimmingWords().components(separatedBy: legalTokens.inverted).joined(separator: "")
        if let upTo = cleanedTerm.index(cleanedTerm.startIndex, offsetBy: 1_000, limitedBy: cleanedTerm.endIndex) {
            cleanedTerm = String(cleanedTerm[..<upTo])
        }
        return cleanedTerm.lowercased()
    }

    private func generateRegexPattern(term: String) -> String {
        var regex = "("
        for char in term {
            if let replacement = replacements[char] {
                regex = "\(regex)[\(replacement)]"
            } else {
                regex = "\(regex)\(char)"
            }
        }
        return regex + ")"
    }

    private func highlightResult(text: String, regexPattern: String) -> String {
        let ranges = text.regexRanges(of: regexPattern)

        var textCopy = text
        for range in ranges {
            let snippet = String(textCopy[range.lowerBound..<range.upperBound])
            textCopy = textCopy.replacingOccurrences(of: snippet, with: "<b>\(snippet)<b>")
        }
        return textCopy
    }
}

extension String {
    func trimmingWords() -> String {
        return components(separatedBy: " ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

private extension String {
    func caseInsensitiveComponents(separatedBy separator: String) -> [Substring] {
        let ranges = caseInsensitiveRanges(of: separator)
        var lowerBound = startIndex
        var components: [Substring] = []
        for range in ranges {
            let upperBound = range.lowerBound
            let text = self[lowerBound..<upperBound]
            components.append(text)
            lowerBound = range.upperBound
        }
        components.append(self[lowerBound..<endIndex])
        return components
    }

    private func caseInsensitiveRanges(of term: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var maximum: Range<String.Index>?
        while true {
            if let found = self.range(of: term, options: [.caseInsensitive, .backwards], range: maximum) {
                ranges.append(found)
                maximum = startIndex..<found.lowerBound
            } else {
                break
            }
        }
        return ranges.reversed()
    }

    func regexRanges(of term: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var maximum: Range<String.Index>?
        while true {
            if let found = self.range(of: term, options: [.regularExpression, .backwards], range: maximum) {
                ranges.append(found)
                maximum = startIndex..<found.lowerBound
            } else {
                break
            }
        }
        return ranges.reversed()
    }
}
