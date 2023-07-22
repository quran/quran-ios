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
    func buildAutocompletions(searchResults: [String], term: String) -> [String] {
        var result: [String] = []
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
                    result.append(subrow)
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
            let ranges = verse.text.regexRanges(of: searchRegex)
            let result = SearchResult(text: verse.text, ranges: ranges, ayah: verse.verse)
            results.append(result)
        }
        return results
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
