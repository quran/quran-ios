//
//  SQLiteSearchableQuranAyahTextPersistence.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/21/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation

class SQLiteSearchableQuranAyahTextPersistence: SearchableAyahTextPersistence {

    private let persistence: SQLiteSearchableAyahTextPersistence

    init(persistence: SQLiteSearchableAyahTextPersistence = SQLiteSearchableAyahTextPersistence(filePath: Files.quranTextPath)) {
        self.persistence = persistence
    }

    // MARK: - Autocomplete

    func autocomplete(term: String) throws -> [SearchAutocompletion] {
        let surasCompletions = autocompleteSuras(for: term)
        let dbCompeltions = try persistence.autocomplete(term: term)
        return surasCompletions + dbCompeltions
    }

    private func autocompleteSuras(for term: String) -> [SearchAutocompletion] {
        let defaultSuraNames = Quran.QuranSurasRange.map { Quran.nameForSura($0, withPrefix: true) }
        let arabicSuraNames = Quran.QuranSurasRange.map { Quran.nameForSura($0, withPrefix: true, language: .arabic) }
        var suraNames = Set(defaultSuraNames)
        arabicSuraNames.forEach { suraNames.insert($0) }
        let surasCompletions = persistence.createAutocompletions(for: Array(suraNames), term: term.trimmingWords(), shouldVerify: false)
        return surasCompletions
    }

    // MARK: - Search

    func search(for term: String) throws -> [SearchResult] {
        let suraResults = searchSuras(for: term)
        let ayahResults = try persistence.search(for: term)
        return suraResults + ayahResults
    }

    private func searchSuras(for term: String) -> [SearchResult] {
        return Quran.QuranSurasRange.flatMap { (sura) -> [SearchResult] in
            let defaultSuraName = Quran.nameForSura(sura, withPrefix: true)
            let arabicSuraName = Quran.nameForSura(sura, withPrefix: true, language: .arabic)
            let suraNames: Set<String> = [defaultSuraName, arabicSuraName]
            let trimmedTerm = term.trimmingWords()
            return suraNames.compactMap { suraName -> SearchResult? in
                guard let range = suraName.range(of: trimmedTerm, options: .caseInsensitive) else {
                    return nil
                }
                let ayah = AyahNumber(sura: sura, ayah: 1)
                var highlightedSuraName = suraName
                highlightedSuraName.insert(contentsOf: "<b>", at: range.upperBound)
                highlightedSuraName.insert(contentsOf: "<b>", at: range.lowerBound)
                return SearchResult(text: highlightedSuraName, ayah: ayah, page: Quran.pageForAyah(ayah))
            }
        }
    }
}
