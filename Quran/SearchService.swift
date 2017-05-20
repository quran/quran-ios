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
    func search(for term: String) -> Observable<[SearchResult]>
}
protocol SearchAutocompletionService {
    func autocompletes(for term: String) -> Observable<[SearchAutocompletion]>
}

class SQLiteSearchService: SearchAutocompletionService, SearchService {

    private let localTranslationInteractor: AnyGetInteractor<[TranslationFull]>
    private let simplePersistence: SimplePersistence
    private let arabicPersistence: AyahTextPersistence
    private let translationPersistenceCreator: AnyCreator<String, AyahTextPersistence>
    init(
        localTranslationInteractor: AnyGetInteractor<[TranslationFull]>,
        simplePersistence: SimplePersistence,
        arabicPersistence: AyahTextPersistence,
        translationPersistenceCreator: AnyCreator<String, AyahTextPersistence>) {
        self.localTranslationInteractor = localTranslationInteractor
        self.simplePersistence = simplePersistence
        self.arabicPersistence = arabicPersistence
        self.translationPersistenceCreator = translationPersistenceCreator
    }

    func autocompletes(for term: String) -> Observable<[SearchAutocompletion]> {

        let translationCreator = self.translationPersistenceCreator
        let arabicPersistence = self.arabicPersistence

        return prepare()
            .map { translations -> [SearchAutocompletion] in
                let arabicResults = try arabicPersistence.searchForAutcompleting(term: term)
                guard arabicResults.isEmpty else {
                    return arabicResults
                }
                for translation in translations {
                    let fileURL = Files.translationsURL.appendingPathComponent(translation.fileName)
                    let persistence = translationCreator.create(fileURL.absoluteString)
                    let results = try persistence.searchForAutcompleting(term: term)
                    if !results.isEmpty {
                        return results
                    }
                }
                return []
            }
    }

    func search(for term: String) -> Observable<[SearchResult]> {
        let translationCreator = self.translationPersistenceCreator
        let arabicPersistence = self.arabicPersistence

        return prepare()
            .map { translations -> [SearchResult] in
                let arabicResults = try arabicPersistence.search(for: term)
                guard arabicResults.isEmpty else {
                    return arabicResults
                }
                for translation in translations {
                    let fileURL = Files.translationsURL.appendingPathComponent(translation.fileName)
                    let persistence = translationCreator.create(fileURL.absoluteString)
                    let results = try persistence.search(for: term)
                    if !results.isEmpty {
                        return results
                    }
                }
                return []
            }
    }

    private func prepare() -> Observable<[Translation]> {
        let persistence = self.simplePersistence
        return localTranslationInteractor
            .get()
            .asObservable()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .default))
            .map { allTranslations -> [Translation] in
                let selectedTranslationsIds = Set(persistence.valueForKey(.selectedTranslations))
                return allTranslations
                    .map { $0.translation }
                    .filter { selectedTranslationsIds.contains($0.id) }
            }
    }
}
