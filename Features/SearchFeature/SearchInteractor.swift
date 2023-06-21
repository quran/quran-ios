//
//  SearchInteractor.swift
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

import Analytics
import Combine
import FeaturesSupport
import Foundation
import QuranKit
import QuranText
import QuranTextKit
import ReadingService
import TranslationService
import UIx
import Utilities
import VLogging

// MARK: - Interactor

@MainActor
final class SearchInteractor {
    // MARK: Lifecycle

    init(analytics: AnalyticsLibrary, searchService: Searcher, recentsService: SearchRecentsService) {
        self.analytics = analytics
        self.searchService = searchService
        self.recentsService = recentsService

        let readingPreferences = readingPreferences

        readingPreferences.$reading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.presenter?.resetSearchBar() }
            .store(in: &cancellables)

        // auto completion
        searchTerm
            .throttle(for: .milliseconds(300), scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()
            .asyncMap { query async -> [SearchAutocompletion] in
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    return []
                }
                do {
                    let quran = readingPreferences.reading.quran
                    return try await searchService.autocomplete(term: query, quran: quran)
                } catch {
                    logger.error("Error while trying to autocomplete. Error: \(error)")
                    return []
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completions in
                self?.presenter?.show(autocompletions: completions)
            }
            .store(in: &cancellables)
    }

    // MARK: Internal

    weak var listener: QuranNavigator?
    weak var presenter: SearchPresenter?

    func onViewLoaded() {
        recentsUpdated()
    }

    func onSearchTermSelected(_ term: String) {
        // update the model
        searchTerm.send(term)

        // start searching
        search()
    }

    func onSelected(searchResult: SearchResult, source: SearchResults.Source) {
        // show translation if not an active translation
        switch source {
        case .quran: break
        case .translation(let translation):
            contentStatePreferences.quranMode = .translation
            var translationIds = selectedTranslationsPreferences.selectedTranslations
            if !translationIds.contains(translation.id) {
                translationIds.append(translation.id)
                selectedTranslationsPreferences.selectedTranslations = translationIds
            }
        }

        // navigate to the selected page
        analytics.openingQuran(from: .searchResults)
        let page = searchResult.ayah.page
        listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: searchResult.ayah)
    }

    func search(term: String) {
        // update the model
        searchTerm.send(term)

        // start searching
        search()
    }

    func onSearchButtonTapped() {
        // start searching
        search()
    }

    func onSearchTextUpdated(to term: String, isActive: Bool) {
        // update the model
        searchTerm.send(term)
    }

    // MARK: Private

    private var cancellables: Set<AnyCancellable> = []
    private let searchTerm = CurrentValueSubject<String, Never>("")

    private let analytics: AnalyticsLibrary
    private let readingPreferences = ReadingPreferences.shared
    private let searchService: Searcher
    private let contentStatePreferences = QuranContentStatePreferences.shared
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
    private let recentsService: SearchRecentsService

    private func recentsUpdated() {
        presenter?.show(recents: recentsService.getRecents(), popular: recentsService.getPopularTerms())
    }

    private func search() {
        Task {
            await asyncSearch()
        }
    }

    private func asyncSearch() async {
        presenter?.showLoading()

        let term = searchTerm.value
        do {
            let results = try await searchService.search(for: term, quran: readingPreferences.reading.quran)

            if term != searchTerm.value {
                return
            }
            let sum = results.reduce(0) { $0 + $1.items.count }
            let source = results.isEmpty ? .quran : results[0].source
            analytics.searching(for: term, source: source, sections: results.count, resultsCount: sum)
            if results.isEmpty {
                presenter?.showNoResults(for: term)
            } else {
                presenter?.show(results: results)
            }
        } catch {
            if term != searchTerm.value {
                return
            }
            presenter?.show(results: [])
            presenter?.showError(error)
        }

        if term != searchTerm.value {
            return
        }
        recentsService.addToRecents(term)
        recentsUpdated()
    }
}

private extension AnalyticsLibrary {
    func searching(
        for term: String,
        source: SearchResults.Source,
        sections: Int, resultsCount: Int
    ) {
        logEvent("SearchTerm", value: term)
        logEvent("SearchSource", value: source.name)
        logEvent("SearchSections", value: sections.description)
        logEvent("SearchResultsCount", value: resultsCount.description)
    }
}
