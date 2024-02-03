//
//  SearchViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-07-17.
//

import Analytics
import Combine
import Foundation
import QuranKit
import QuranText
import QuranTextKit
import ReadingService
import TranslationService
import VLogging

@MainActor
final class SearchViewModel: ObservableObject {
    // MARK: Lifecycle

    init(analytics: AnalyticsLibrary, searchService: CompositeSearcher, navigateTo: @escaping (AyahNumber) -> Void) {
        self.analytics = analytics
        self.searchService = searchService
        self.navigateTo = navigateTo
    }

    // MARK: Internal

    @Published var error: Error? = nil

    @Published var searchState = SearchState.searching

    @Published var searchTerm = ""
    @Published var autocompletions: [String] = []
    @Published var recents: [String] = []

    @Published var keyboardState: KeyboardState = .closed

    @Published var uiState = SearchUIState.entry {
        didSet {
            logger.debug("[Search] New UI state: \(uiState)")
        }
    }

    var populars: [String] { recentsService.popularTerms }

    func start() async {
        async let reading: () = observeReadingChanges()
        async let autocomplete: () = observeSearchTermChanges()
        async let recents: () = observeRecentSearchItemsChanges()
        async let search: () = observeSearchChanges()
        _ = await [reading, autocomplete, recents, search]
    }

    func select(searchResult: SearchResult, source: SearchResults.Source) {
        logger.info("Search: search result selected '\(searchResult)', source: \(source)")
        // show translation if not an active translation
        switch source {
        case .quran: break
        case .translation(let translation):
            contentStatePreferences.quranMode = .translation
            var translationIds = selectedTranslationsPreferences.selectedTranslationIds
            if !translationIds.contains(translation.id) {
                translationIds.append(translation.id)
                selectedTranslationsPreferences.selectedTranslationIds = translationIds
            }
        }

        // navigate to the selected page
        analytics.openingQuran(from: .searchResults)
        navigateTo(searchResult.ayah)
    }

    func reset() {
        uiState = .entry
        searchTerm = ""
        autocompletions = []
    }

    func autocomplete(_ term: String) {
        if searchTerm != term {
            uiState = .entry
            searchTerm = term
        }
    }

    func searchForUserTypedTerm() {
        search(for: searchTerm)
    }

    func search(for term: String) {
        keyboardState = .closed
        searchTerm = term
        uiState = .search(term)
    }

    // MARK: Private

    private let analytics: AnalyticsLibrary
    private let searchService: CompositeSearcher
    private let navigateTo: (AyahNumber) -> Void

    private let recentsService = SearchRecentsService.shared
    private let readingPreferences = ReadingPreferences.shared
    private let contentStatePreferences = QuranContentStatePreferences.shared
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared

    private func search(for term: String) async throws -> [SearchResults] {
        searchState = .searching
        let quran = readingPreferences.reading.quran
        let results = try await searchService.search(for: term, quran: quran)

        analytics.searching(for: term, results: results)
        recentsService.addToRecents(term)

        return results
    }

    private func observeSearchChanges() async {
        let states = $uiState.values()
        for await state in states {
            switch state {
            case .entry:
                continue
            case .search(let term):
                searchState = .searching
                let result = await Result(catching: { try await search(for: term) })
                if searchTerm == term {
                    switch result {
                    case .success(let results):
                        searchState = .searchResult(results)
                    case .failure(let error):
                        self.error = error
                        searchState = .searchResult([])
                    }
                }
            }
        }
    }

    private func observeRecentSearchItemsChanges() async {
        let recentsSequence = recentsService.$recentSearchItems
            .prepend(recentsService.recentSearchItems)
            .values()
        for await recents in recentsSequence {
            self.recents = recents
        }
    }

    private func observeReadingChanges() async {
        let readings = readingPreferences.$reading
            .values()
        for await _ in readings {
            searchTerm = ""
        }
    }

    private func observeSearchTermChanges() async {
        let searchTermSequence = $searchTerm
            .dropFirst() // Drop initial empty value.
            .throttle(for: .milliseconds(300), scheduler: DispatchQueue.main, latest: true)
            .values()
        for await term in searchTermSequence {
            logger.debug("[Search] Autocomplete requested for \(term)")
            let autocompletions = await autocomplete(term)
            if searchTerm == term {
                self.autocompletions = autocompletions
            }
        }
    }

    private func autocomplete(_ term: String) async -> [String] {
        let quran = readingPreferences.reading.quran
        return await searchService.autocomplete(term: term, quran: quran)
    }
}

private extension AnalyticsLibrary {
    func searching(for term: String, results: [SearchResults]) {
        logEvent("SearchTerm", value: term)
        logEvent("SearchSections", value: results.count.description)
        for result in results {
            logEvent("SearchSource", value: result.source.name)
            logEvent("SearchResultsCount", value: result.items.count.description)
        }
    }
}
