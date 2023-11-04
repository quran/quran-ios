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

enum SearchUIType {
    case entry
    case autocomplete
    case loading
    case searchResults
}

struct SearchTerm {
    let term: String
    let autocomplete: Bool

    static func autocomple(_ term: String) -> Self {
        SearchTerm(term: term, autocomplete: true)
    }

    static func noAction(_ term: String) -> Self {
        SearchTerm(term: term, autocomplete: false)
    }
}

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

    @Published var searchType = SearchUIType.entry

    @Published var searchTerm = SearchTerm(term: "", autocomplete: false)
    @Published var autocompletions: [String] = []
    @Published var searchResults: [SearchResults] = []
    @Published var recents: [String] = []

    let resignSearchBar = PassthroughSubject<Void, Never>()

    var populars: [String] { recentsService.popularTerms }

    func start() async {
        async let reading: () = observeReadingChanges()
        async let autocomplete: () = observeSearchTermChanges()
        async let recents: () = observeRecentChanges()
        _ = await [reading, autocomplete, recents]
    }

    func select(searchResult: SearchResult, source: SearchResults.Source) {
        logger.info("Search: search result selected '\(searchResult)', source: \(source)")
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
        navigateTo(searchResult.ayah)
    }

    func search(searchTerm term: String) async {
        resignSearchBar.send()
        searchTerm = .noAction(term)
        await search()
    }

    func search() async {
        searchType = .loading

        let term = searchTerm.term
        do {
            let quran = readingPreferences.reading.quran
            let results = try await searchService.search(for: term, quran: quran)
            analytics.searching(for: term, results: results)

            if searchTerm.term == term {
                searchResults = results
                recentsService.addToRecents(term)

                searchType = .searchResults
            }
        } catch {
            logger.error("Error while searching. Error: \(error)")
            if searchTerm.term != term {
                return
            }
            searchResults = []
            self.error = error
            searchType = .searchResults
        }
    }

    // MARK: Private

    private let analytics: AnalyticsLibrary
    private let searchService: CompositeSearcher
    private let navigateTo: (AyahNumber) -> Void

    private let recentsService = SearchRecentsService.shared
    private let readingPreferences = ReadingPreferences.shared
    private let contentStatePreferences = QuranContentStatePreferences.shared
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared

    private func observeRecentChanges() async {
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
            searchTerm = .noAction("")
        }
    }

    private func observeSearchTermChanges() async {
        let searchTermSequence = $searchTerm
            .dropFirst()
            .filter(\.autocomplete)
            .map(\.term)
            .throttle(for: .milliseconds(300), scheduler: DispatchQueue.main, latest: true)
            .values()
        for await term in searchTermSequence {
            if searchType == .loading {
                continue
            }

            let autocompletions = await autocomplete(term)
            if searchTerm.term == term {
                self.autocompletions = autocompletions
                if !autocompletions.isEmpty {
                    searchType = .autocomplete
                } else {
                    searchType = .entry
                }
            }
        }
    }

    private func autocomplete(_ term: String) async -> [String] {
        if term.trimmingCharacters(in: .whitespaces).isEmpty {
            return []
        }
        do {
            let quran = readingPreferences.reading.quran
            return try await searchService.autocomplete(term: term, quran: quran)
        } catch {
            logger.error("Error while trying to autocomplete. Error: \(error)")
            return []
        }
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
