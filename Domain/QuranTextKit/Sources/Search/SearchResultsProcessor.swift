//
//  SearchResultsProcessor.swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import Foundation
import QuranKit
import QuranText

struct SearchResultsProcessor {
    // MARK: Internal

    func buildAutocompletions(searchResults: [String], term: String) -> [SearchAutocompletion] {
        var result: [SearchAutocompletion] = []
        var added: Set<String> = []
        for text in searchResults {
            let suffixes = text.caseInsensitiveComponents(separatedBy: term)
            for suffixIndex in 1 ..< suffixes.count {
                let suffix = suffixes[suffixIndex]
                let suffixWords = suffix.components(separatedBy: " ").prefix(5)
                let trimmedSuffix = suffixWords.joined(separator: " ")
                if trimmedSuffix.rangeOfCharacter(from: CharacterSet.whitespaces.union(.alphanumerics).inverted) != nil {
                    continue
                }
                let subrow = term + trimmedSuffix
                if !added.contains(subrow) {
                    added.insert(subrow)
                    let autocompletion = SearchAutocompletion(text: subrow, term: term)
                    result.append(autocompletion)
                }
            }
        }

        return result
    }

    func buildSearchResults(searchRegex: String, verses: [(verse: AyahNumber, text: String)]) -> [SearchResult] {
        var results: [SearchResult] = []
        for verse in verses {
            if verse.text.range(of: searchRegex, options: [.regularExpression, .caseInsensitive]) == nil {
                continue
            }
            let highlightedText = highlightResult(text: verse.text, regexPattern: searchRegex)
            let result = SearchResult(text: highlightedText, ayah: verse.verse)
            results.append(result)
        }
        return results
    }

    // MARK: Private

    private func highlightResult(text: String, regexPattern: String) -> String {
        let ranges = text.regexRanges(of: regexPattern)

        var textCopy = text
        for range in ranges {
            let snippet = String(textCopy[range.lowerBound ..< range.upperBound])
            textCopy = textCopy.replacingOccurrences(of: snippet, with: "<b>\(snippet)<b>")
        }
        return textCopy
    }
}

private extension String {
    func caseInsensitiveComponents(separatedBy separator: String) -> [Substring] {
        let ranges = caseInsensitiveRanges(of: separator)
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

    private func caseInsensitiveRanges(of term: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var maximum: Range<String.Index>?
        while true {
            if let found = range(of: term, options: [.caseInsensitive, .backwards], range: maximum) {
                ranges.append(found)
                maximum = startIndex ..< found.lowerBound
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
            if let found = range(of: term, options: [.regularExpression, .backwards], range: maximum) {
                ranges.append(found)
                maximum = startIndex ..< found.lowerBound
            } else {
                break
            }
        }
        return ranges.reversed()
    }
}
