//
//  SearchTermProcessor.swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import Foundation
import QuranKit
import QuranText

private enum SearchRegex {
    /// Match unicode category Separators (Z).
    static let spaceRegex = "\\p{Z}+"
    /// Match unicode categories Marks (M), Punctuation (P), Symbols (S), Control (C) and Arabic Tatweel character.
    static let invalidSearchRegex = "[\\p{M}\\p{P}\\p{S}\\p{C}\u{0640}]"
    static let arabicSimilarityRegex = "[\u{0627}\u{0623}\u{0621}\u{062a}\u{0629}\u{0647}\u{0649}\u{0626}]"
    static let arabicSimilarityReplacements: [Character: String] = [
        // given: ا
        // match: آأإاﻯ
        "\u{0627}": "\u{0622}\u{0623}\u{0625}\u{0627}\u{0649}",

        // given: ﺃ
        // match: ﺃﺀﺆﺋ
        "\u{0623}": "\u{0621}\u{0623}\u{0624}\u{0626}",

        // given: ﺀ
        // match: ﺀﺃﺆ
        "\u{0621}": "\u{0621}\u{0623}\u{0624}\u{0626}",

        // given: ﺕ
        // match: ﺕﺓ
        "\u{062a}": "\u{062a}\u{0629}",

        // given: ﺓ
        // match: ﺓتﻫ
        "\u{0629}": "\u{0629}\u{062a}\u{0647}",

        // given: ه
        // match: ةه
        "\u{0647}": "\u{0647}\u{0629}",

        // given: ﻯ
        // match: ﻯي
        "\u{0649}": "\u{0649}\u{064a}",

        // given: ئ
        // match: ئﻯي
        "\u{0626}": "\u{0626}\u{0649}\u{064a}",
    ]
}

struct SearchTerm {
    // MARK: Lifecycle

    init?(_ value: String) {
        compactQuery = value.trimmedWords()
        if compactQuery.isEmpty {
            return nil
        }
        persistenceQuery = compactQuery.removeInvalidSearchCharacters()
        guard let resultRegex = Self.regexForArabicSimilarityCharacters(persistenceQuery) else {
            return nil
        }
        queryRegex = resultRegex
    }

    // MARK: Internal

    var compactQuery: String
    var persistenceQuery: String

    static func regexForArabicSimilarityCharacters(_ value: String) -> NSRegularExpression? {
        let cleanedValue = value.removeInvalidSearchCharacters()
        var regex = ""
        for char in cleanedValue {
            if let replacement = SearchRegex.arabicSimilarityReplacements[char] {
                regex += "[\(replacement)]"
            } else {
                regex += String(char)
            }
            regex += SearchRegex.invalidSearchRegex + "*"
        }
        return try? NSRegularExpression(pattern: "(" + regex + ")", options: .caseInsensitive)
    }

    func persistenceQueryReplacingArabicSimilarityCharactersWithUnderscore() -> String {
        persistenceQuery.replacingOccurrences(
            of: SearchRegex.arabicSimilarityRegex,
            with: "_",
            options: .regularExpression
        )
    }

    func buildAutocompletions(searchResults: [String]) -> [String] {
        var result: [String] = []
        var added: Set<String> = []
        for searchResult in searchResults {
            for text in [searchResult, searchResult.decomposedStringWithCompatibilityMapping] {
                let suffixes = text.caseInsensitiveComponents(separatedBy: queryRegex)
                for suffixIndex in 1 ..< suffixes.count {
                    let suffix = suffixes[suffixIndex]
                    // Include only first 5 words
                    let suffixWords = suffix.components(separatedBy: " ").prefix(5).joined(separator: " ")
                    let charSetToTrim = CharacterSet.whitespaces.union(.alphanumerics).inverted
                    let trimmedSuffix = suffixWords.trimmingCharacters(in: charSetToTrim)
                    if trimmedSuffix.isEmpty && suffixWords != trimmedSuffix {
                        continue
                    }
                    let subrow = persistenceQuery + trimmedSuffix
                    if !added.contains(subrow) {
                        added.insert(subrow)
                        result.append(subrow)
                    }
                }
            }
        }
        return result
    }

    func buildSearchResults(verses: [(verse: AyahNumber, text: String)]) -> [SearchResult] {
        var results: [SearchResult] = []
        for verse in verses {
            for text in [verse.text, verse.text.decomposedStringWithCompatibilityMapping] {
                let ranges = text.split(separatedBy: queryRegex)
                if !ranges.isEmpty {
                    let result = SearchResult(text: text, ranges: ranges, ayah: verse.verse)
                    results.append(result)
                    break
                }
            }
        }
        return results
    }

    // MARK: Private

    private var queryRegex: NSRegularExpression
}

extension String {
    func removeInvalidSearchCharacters() -> String {
        var cleanedTerm = replacingOccurrences(of: SearchRegex.invalidSearchRegex, with: "", options: .regularExpression)
            .replacingOccurrences(of: SearchRegex.spaceRegex, with: " ", options: .regularExpression)

        if let upTo = cleanedTerm.index(cleanedTerm.startIndex, offsetBy: 1000, limitedBy: cleanedTerm.endIndex) {
            cleanedTerm = String(cleanedTerm[..<upTo])
        }
        return cleanedTerm.lowercased()
    }

    func caseInsensitiveComponents(separatedBy separator: NSRegularExpression) -> [Substring] {
        let ranges = split(separatedBy: separator)
        var lowerBound = startIndex
        var components: [Substring] = []
        for range in ranges {
            let upperBound = range.lowerBound
            let text = self[lowerBound ..< upperBound]
            components.append(text)
            lowerBound = range.upperBound
        }
        components.append(self[lowerBound ..< endIndex])
        return components
    }

    func split(separatedBy regex: NSRegularExpression) -> [Range<String.Index>] {
        let nsRange = NSRange(startIndex..., in: self)
        let matches = regex.matches(in: self, range: nsRange)

        return matches.compactMap {
            Range($0.range, in: self)
        }
    }

    func containsArabic() -> Bool {
        range(of: "\\p{Arabic}", options: .regularExpression) != nil
    }

    func containsOnlyNumbers() -> Bool {
        removeInvalidSearchCharacters().range(of: "^[0-9]+$", options: .regularExpression) != nil
    }

    func trimmedWords() -> String {
        components(separatedBy: " ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
