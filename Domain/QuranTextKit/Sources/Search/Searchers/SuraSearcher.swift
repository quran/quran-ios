//
//  SuraSearcher.swift
//
//
//  Created by Mohamed Afifi on 2021-11-16.
//

import QuranKit
import QuranText

struct SuraSearcher: Searcher {
    func autocomplete(term: SearchTerm, quran: Quran) throws -> [String] {
        let defaultSuraNames = quran.suras.map { $0.localizedName(withPrefix: true) }
        let arabicSuraNames = quran.suras.map { $0.localizedName(withPrefix: true, language: .arabic) }
        var suraNames = Set(defaultSuraNames)
        arabicSuraNames.forEach { suraNames.insert($0) }
        let surasCompletions = term.buildAutocompletions(searchResults: Array(suraNames))
        return surasCompletions
    }

    func search(for term: SearchTerm, quran: Quran) throws -> [SearchResults] {
        let items = quran.suras.flatMap { sura -> [SearchResult] in
            let defaultSuraName = sura.localizedName(withPrefix: true)
            let arabicSuraName = sura.localizedName(withPrefix: true, language: .arabic)
            let suraNames: Set<String> = [defaultSuraName, arabicSuraName]
            return suraNames.flatMap { suraName in
                let results = term.buildSearchResults(verses: [(verse: sura.firstVerse, text: suraName)])
                return results
            }
        }
        return [SearchResults(source: .quran, items: items)]
    }
}
