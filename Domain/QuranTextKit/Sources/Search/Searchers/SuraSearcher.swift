//
//  SuraSearcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import QuranKit
import QuranText

struct SuraSearcher: Searcher {
    // MARK: Internal

    func autocomplete(term: String, quran: Quran) throws -> [SearchAutocompletion] {
        let defaultSuraNames = quran.suras.map { $0.localizedName(withPrefix: true) }
        let arabicSuraNames = quran.suras.map { $0.localizedName(withPrefix: true, language: .arabic) }
        var suraNames = Set(defaultSuraNames)
        arabicSuraNames.forEach { suraNames.insert($0) }
        let surasCompletions = resultsProcessor.buildAutocompletions(searchResults: Array(suraNames), term: term.trimmingWords())
        return surasCompletions
    }

    func search(for term: String, quran: Quran) throws -> [SearchResults] {
        let items = quran.suras.flatMap { sura -> [SearchResult] in
            let defaultSuraName = sura.localizedName(withPrefix: true)
            let arabicSuraName = sura.localizedName(withPrefix: true, language: .arabic)
            let suraNames: Set<String> = [defaultSuraName, arabicSuraName]
            let trimmedTerm = term.trimmingWords()
            return suraNames.compactMap { suraName -> SearchResult? in
                guard let range = suraName.range(of: trimmedTerm, options: .caseInsensitive) else {
                    return nil
                }
                let ayah = sura.firstVerse
                var highlightedSuraName = suraName
                highlightedSuraName.insert(contentsOf: "<b>", at: range.upperBound)
                highlightedSuraName.insert(contentsOf: "<b>", at: range.lowerBound)
                return SearchResult(text: highlightedSuraName, ayah: ayah)
            }
        }
        return [SearchResults(source: .quran, items: items)]
    }

    // MARK: Private

    private let resultsProcessor = SearchResultsProcessor()
}

private extension String {
    func trimmingWords() -> String {
        components(separatedBy: " ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
