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
    private let localTranslationInteractor: AnyGetInteractor<[TranslationFull]>
    private let arabicPersistence: AyahTextPersistence
    private let translationPersistenceCreator: AnyCreator<String, AyahTextPersistence>
    init(
        localTranslationInteractor: AnyGetInteractor<[TranslationFull]>,
        simplePersistence: SimplePersistence,
        arabicPersistence: AyahTextPersistence,
        translationPersistenceCreator: AnyCreator<String, AyahTextPersistence>) {
        self.localTranslationInteractor = localTranslationInteractor
        self.arabicPersistence = arabicPersistence
        self.translationPersistenceCreator = translationPersistenceCreator
    }

    func autocomplete(term: String) -> Observable<[SearchAutocompletion]> {

        let translationCreator = self.translationPersistenceCreator
        let arabicPersistence = self.arabicPersistence

        return prepare()
            .map { translations -> [SearchAutocompletion] in
                let arabicResults = try arabicPersistence.autocomplete(term: term)
                guard arabicResults.isEmpty else {
                    return arabicResults
                }
                for translation in translations {
                    let fileURL = Files.translationsURL.appendingPathComponent(translation.fileName)
                    let persistence = translationCreator.create(fileURL.absoluteString)
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
        let translationCreator = self.translationPersistenceCreator
        let arabicPersistence = self.arabicPersistence
        let ayahNumber = self.isAyahNumberSearch(term)

        return prepare()
            .map { translations -> SearchResults in

                if let ayah = ayahNumber {
                    let ayahText = try arabicPersistence.getAyahTextForNumber(ayah)
                    let result = SearchResult(text: ayahText, ayah: ayah, page: Quran.pageForAyah(ayah))
                    return SearchResults(source: .quran, items: [result])
                } else {
                    let arabicResults = try arabicPersistence.search(for: term)
                    guard arabicResults.isEmpty else {
                        return SearchResults(source: .quran, items: arabicResults)
                    }
                    for translation in translations {
                        let fileURL = Files.translationsURL.appendingPathComponent(translation.fileName)
                        let persistence = translationCreator.create(fileURL.absoluteString)
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
        return localTranslationInteractor
            .get()
            .asObservable()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .default))
            .map { allTranslations -> [Translation] in
                return allTranslations
                    .filter { $0.isDownloaded }
                    .map { $0.translation }
            }
    }

    private func isAyahNumberSearch(_ term: String) -> AyahNumber? {
        let components = term.components(separatedBy: ":")
        guard !components.isEmpty && components.count <= 2 else {
            return nil
        }
        guard let sura = parseInt(components[0]) else {
            return nil
        }
        guard sura >= Quran.QuranSurasRange.lowerBound && sura <= Quran.QuranSurasRange.upperBound else {
            return nil
        }
        if components.count == 1 {
            return AyahNumber(sura: sura, ayah: 1)
        } else {
            guard let ayah = parseInt(components[1]) else {
                return nil
            }
            guard ayah > 0 && ayah <= Quran.numberOfAyahsForSura(sura) else {
                return nil
            }
            return AyahNumber(sura: sura, ayah: ayah)
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
