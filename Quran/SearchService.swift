//
//  SearchService.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/17/17.
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
import RxSwift

protocol SearchService {
    func search(for term: String) -> Observable<SearchResults>
}
protocol SearchAutocompletionService {
    func autocomplete(term: String) -> Observable<[SearchAutocompletion]>
}

class SQLiteSearchService: SearchAutocompletionService, SearchService {

    private let numberParser: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()
    private let localTranslationRetriever: LocalTranslationsRetrieverType
    private let quranAyahTextPersistence: QuranAyahTextPersistence
    private let searchableQuranPersistence: SearchableAyahTextPersistence
    private let searchableTranslationPersistenceBuilder: SearchableTranslationAyahTextPersistenceBuildable
    init(
        localTranslationRetriever: LocalTranslationsRetrieverType,
        simplePersistence: SimplePersistence,
        searchableQuranPersistence: SearchableAyahTextPersistence,
        quranAyahTextPersistence: QuranAyahTextPersistence,
        searchableTranslationPersistenceBuilder: SearchableTranslationAyahTextPersistenceBuildable) {
        self.localTranslationRetriever = localTranslationRetriever
        self.quranAyahTextPersistence = quranAyahTextPersistence
        self.searchableQuranPersistence = searchableQuranPersistence
        self.searchableTranslationPersistenceBuilder = searchableTranslationPersistenceBuilder
    }

    func autocomplete(term: String) -> Observable<[SearchAutocompletion]> {

        let searchableTranslationPersistenceBuilder = self.searchableTranslationPersistenceBuilder
        let searchableQuranPersistence = self.searchableQuranPersistence

        return prepare()
            .map { translations -> [SearchAutocompletion] in
                let arabicResults = try searchableQuranPersistence.autocomplete(term: term)
                guard arabicResults.isEmpty else {
                    return arabicResults
                }
                for translation in translations {
                    let fileURL = Files.translationsURL.appendingPathComponent(translation.fileName)
                    let persistence = searchableTranslationPersistenceBuilder.build(with: fileURL.absoluteString)
                    let results = try persistence.autocomplete(term: term)
                    if !results.isEmpty {
                        return results
                    }
                }
                return []
            }
            .map { [SearchAutocompletion(text: term, highlightedRange: term.startIndex..<term.endIndex)] + $0 }
            .map { $0.orderedUnique() }
    }

    func search(for term: String) -> Observable<SearchResults> {
        let searchableTranslationPersistenceBuilder = self.searchableTranslationPersistenceBuilder
        let searchableQuranPersistence = self.searchableQuranPersistence

        return prepare()
            .map { translations -> SearchResults in

                let numberResults = try self.getNumberSearchResults(term)
                if !numberResults.isEmpty {
                    return SearchResults(source: .quran, items: numberResults)
                } else {
                    let arabicResults = try searchableQuranPersistence.search(for: term)
                    guard arabicResults.isEmpty else {
                        return SearchResults(source: .quran, items: arabicResults)
                    }
                    for translation in translations {
                        let fileURL = Files.translationsURL.appendingPathComponent(translation.fileName)
                        let persistence = searchableTranslationPersistenceBuilder.build(with: fileURL.absoluteString)
                        let results = try persistence.search(for: term)
                        if !results.isEmpty {
                            return SearchResults(source: .translation(translation), items: results)
                        }
                    }
                    return SearchResults(source: .none, items: [])
                }
            }
    }

    private func prepare() -> Observable<[Translation]> {
        return localTranslationRetriever
            .getLocalTranslations()
            .asObservable()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .default))
            .map { allTranslations -> [Translation] in
                return allTranslations
                    .filter { $0.isDownloaded }
                    .map { $0.translation }
            }
    }

    private func getNumberSearchResults(_ term: String) throws -> [SearchResult] {
        let components = parseIntArray(term)
        guard !components.isEmpty else {
            return []
        }
        if components.count == 2 {
            return [try parseAyahResult(sura: components[0], ayah: components[1])].compactMap { $0 }
        } else {
            return [
                parseSuraResult(sura: components[0]),
                parseJuzResult(juz: components[0]),
                parseHizbResult(hizb: components[0]),
                parsePageResult(page: components[0])
            ].compactMap { $0 }
        }
    }

    private func parseAyahResult(sura: Int, ayah: Int) throws -> SearchResult? {
        guard sura >= Quran.QuranSurasRange.lowerBound && sura <= Quran.QuranSurasRange.upperBound else {
            return nil
        }
        guard ayah > 0 && ayah <= Quran.numberOfAyahsForSura(sura) else {
            return nil
        }
        let ayahNumber = AyahNumber(sura: sura, ayah: ayah)
        let ayahText = try quranAyahTextPersistence.getQuranAyahTextForNumber(ayahNumber)
        return SearchResult(text: ayahText, ayah: ayahNumber, page: Quran.pageForAyah(ayahNumber))
    }

    private func parseSuraResult(sura: Int) -> SearchResult? {
        guard sura >= Quran.QuranSurasRange.lowerBound && sura <= Quran.QuranSurasRange.upperBound else {
            return nil
        }
        let ayahNumber = AyahNumber(sura: sura, ayah: 1)
        return SearchResult(text: Quran.nameForSura(sura, withPrefix: true), ayah: ayahNumber, page: Quran.pageForAyah(ayahNumber))
    }

    private func parsePageResult(page: Int) -> SearchResult? {
        guard page >= Quran.QuranPagesRange.lowerBound && page <= Quran.QuranPagesRange.upperBound else {
            return nil
        }
        let ayahNumber = Quran.startAyahForPage(page)
        let format = "\(lAndroid("quran_page")) %d"
        let text = String.localizedStringWithFormat(format, page)
        return SearchResult(text: text, ayah: ayahNumber, page: Quran.pageForAyah(ayahNumber))
    }

    private func parseJuzResult(juz: Int) -> SearchResult? {
        guard juz >= Quran.QuranJuzsRange.lowerBound && juz <= Quran.QuranJuzsRange.upperBound else {
            return nil
        }
        let ayahNumber = Quran.Quarters[(juz - 1) * Quran.NumberOfQuartersPerJuz]
        let format = "\(lAndroid("quran_juz2")) %d"
        let text = String.localizedStringWithFormat(format, juz)
        return SearchResult(text: text, ayah: ayahNumber, page: Quran.pageForAyah(ayahNumber))
    }

    private func parseHizbResult(hizb: Int) -> SearchResult? {
        let numberOfHizbsPerJuz = 2
        let numberOfQuartersPerHizb = Quran.NumberOfQuartersPerJuz / numberOfHizbsPerJuz
        guard hizb >= 1 && hizb <= Quran.Quarters.count / numberOfQuartersPerHizb else {
            return nil
        }

        let ayahNumber = Quran.Quarters[(hizb - 1) * numberOfQuartersPerHizb]
        let format = "\(lAndroid("quran_hizb")) %d"
        let text = String.localizedStringWithFormat(format, hizb)
        return SearchResult(text: text, ayah: ayahNumber, page: Quran.pageForAyah(ayahNumber))
    }

    private func parseIntArray(_ term: String) -> [Int] {
        let components = term.components(separatedBy: ":")
        guard !components.isEmpty && components.count <= 2 else {
            return []
        }
        guard let first = parseInt(components[0]) else {
            return []
        }
        if components.count == 1 {
            return [first]
        } else {
            guard let second = parseInt(components[1]) else {
                return []
            }
            return [first, second]
        }
    }

    private func parseInt(_ value: String) -> Int? {
        guard let number = numberParser.number(from: value) else {
            return nil
        }
        switch CFNumberGetType(number) {
        case .charType, .intType, .nsIntegerType, .shortType, .sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type:
            return number.intValue
        default: return nil
        }
    }
}
