//
//  SearchBuilder.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/15/17.
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
protocol SearchBuildable: class {
    func build(withListener listener: SearchListener) -> SearchRouting
}

class SearchBuilder: Builder, SearchBuildable {

    func build(withListener listener: SearchListener) -> SearchRouting {
        let viewController = SearchViewController()
        let presenter = SearchPresenter(viewController: viewController)
        let interactor = SearchInteractor(
            presenter: presenter,
            persistence: container.createSimplePersistence(),
            autocompleteService: createSQLiteSearchService(),
            searchService: createSQLiteSearchService(),
            recentsService: container.createDefaultSearchRecentsService())
        interactor.listener = listener
        return SearchRouter(interactor: interactor, viewController: viewController)
    }

    private func createSQLiteSearchService() -> SearchService & SearchAutocompletionService {
        return SQLiteSearchService(
            localTranslationRetriever: container.createLocalTranslationsRetriever(),
            simplePersistence: container.createSimplePersistence(),
            searchableQuranPersistence: SQLiteSearchableQuranAyahTextPersistence(),
            quranAyahTextPersistence: SQLiteQuranAyahTextPersistence(),
            searchableTranslationPersistenceBuilder: SearchableTranslationAyahTextPersistenceBuilder())
    }
}
