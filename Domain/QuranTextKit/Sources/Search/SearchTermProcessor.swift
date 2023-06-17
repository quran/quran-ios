//
//  SearchTermProcessor.swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import Foundation

struct SearchTermProcessor {
    private let regex = "[\u{0627}\u{0623}\u{0621}\u{062a}\u{0629}\u{0647}\u{0649}]"
    private let replacements: [Character: String] = [
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
    ]

    func prepareSearchTermForSearching(_ searchTerm: String) -> (searchTerm: String, pattern: String) {
        let searchTerm = prepareSearchTermForAutocompletion(searchTerm)
        let arabicSearchTerm = searchTerm.replacingOccurrences(
            of: regex,
            with: "_",
            options: .regularExpression
        )
        let pattern = generateRegexPattern(term: searchTerm)
        return (searchTerm: arabicSearchTerm, pattern: pattern)
    }

    func prepareSearchTermForAutocompletion(_ searchTerm: String) -> String {
        let legalTokens = CharacterSet.whitespaces.union(.alphanumerics)
        var cleanedTerm = searchTerm.trimmedWords().components(separatedBy: legalTokens.inverted).joined(separator: "")
        if let upTo = cleanedTerm.index(cleanedTerm.startIndex, offsetBy: 1000, limitedBy: cleanedTerm.endIndex) {
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
}

private extension String {
    func trimmedWords() -> String {
        components(separatedBy: " ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
