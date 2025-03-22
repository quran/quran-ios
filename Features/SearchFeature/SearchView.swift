//
//  SearchView.swift
//
//
//  Created by Mohamed Afifi on 2023-07-17.
//

import Localization
import NoorUI
import QuranKit
import QuranText
import SwiftUI
import UIx

struct SearchView: View {
    @StateObject var viewModel: SearchViewModel

    var body: some View {
        SearchViewUI(
            error: $viewModel.error,
            uiState: viewModel.uiState,
            searchState: viewModel.searchState,
            term: viewModel.searchTerm,
            recents: viewModel.recents,
            populars: viewModel.populars,
            autocompletions: viewModel.autocompletions,
            start: { await viewModel.start() },
            search: { viewModel.search(for: $0) },
            selectSearchResult: { viewModel.select(searchResult: $0.result, source: $0.source) }
        )
    }
}

private struct SearchViewUI: View {
    @Binding var error: Error?

    let uiState: SearchUIState
    let searchState: SearchState

    let term: String
    let recents: [String]
    let populars: [String]
    let autocompletions: [String]

    let start: AsyncAction
    let search: AsyncItemAction<String>
    let selectSearchResult: ItemAction<(result: SearchResult, source: SearchResults.Source)>

    var body: some View {
        Group {
            switch uiState {
            case .entry:
                if autocompletions.isEmpty {
                    entry
                } else {
                    autocompletionsView
                }
            case .search:
                switch searchState {
                case .searching:
                    NoorList {
                        LoadingView()
                    }
                case .searchResult(let results):
                    searchResultsView(searchResults: results)
                }
            }
        }
        .task { await start() }
        .errorAlert(error: $error)
    }

    var noResultsData: some View {
        DataUnavailableView(
            title: lFormat("no_results", table: .android, term),
            text: "",
            image: .search
        )
    }

    @ViewBuilder
    var autocompletionsView: some View {
        NoorList(listType: .searching) {
            NoorSection(autocompletions.map(SelfIdentifiable.init)) { item in
                NoorListItem(
                    image: .init(.search),
                    title: autocompletionText(of: item.value)
                ) {
                    await search(item.value)
                }
            }
        }
    }

    @ViewBuilder
    var entry: some View {
        NoorList {
            NoorSection(title: l("search.recents.title"), recents.map(SelfIdentifiable.init)) { item in
                NoorListItem(
                    image: .init(.search),
                    title: .text(item.value)
                ) {
                    await search(item.value)
                }
            }

            NoorSection(title: l("search.popular.title"), populars.map(SelfIdentifiable.init)) { item in
                NoorListItem(
                    image: .init(.search),
                    title: .text(item.value)
                ) {
                    await search(item.value)
                }
            }
        }
    }

    @ViewBuilder
    func searchResultsView(searchResults: [SearchResults]) -> some View {
        if !searchResults.isEmpty {
            NoorList {
                ForEach(searchResults) { result in
                    let plainTitle = title(of: result)
                    let title = lFormat("search.result.count", plainTitle, result.items.count)
                    NoorSection(title: title, result.items) { item in
                        let localizedVerse = item.ayah.localizedName
                        let arabicSuraName = item.ayah.sura.arabicSuraName
                        NoorListItem(
                            subheading: "\(localizedVerse) \(sura: arabicSuraName)",
                            title: searchResultText(of: item),
                            accessory: .text(NumberFormatter.shared.format(item.ayah.page.pageNumber))
                        ) {
                            selectSearchResult((item, result.source))
                        }
                    }
                }
            }
        } else {
            noResultsData
        }
    }

    func title(of searchResults: SearchResults) -> String {
        switch searchResults.source {
        case .translation(let translation):
            return translation.translationName
        case .quran:
            return (Bundle.main.localizedInfoDictionary?["CFBundleName"] as? String) ?? "Quran"
        }
    }

    func autocompletionText(of item: String) -> MultipartText {
        let ranges = [item.range(of: term, options: .caseInsensitive)].compactMap { $0 }
        let highlightRanges = ranges.map { HighlightingRange($0, foregroundColor: .secondaryLabel) }
        return "\(item, lineLimit: 1, highlighting: highlightRanges)"
    }

    func searchResultText(of item: SearchResult) -> MultipartText {
        let highlightRanges = item.ranges.map { HighlightingRange($0, fontWeight: .heavy) }
        return "\(item.text, highlighting: highlightRanges)"
    }
}

struct SearchView_Previews: PreviewProvider {
    struct Preview: View {
        static let englishText = "This is an autocompletion text in English, what if this is a long text"
        static let arabicText = "هذا خط عربي يوضح خاصية التكملة للعرب"
        static let quran = Quran.hafsMadani1405

        static let populatedResults = SearchResults(source: .quran, items: [
            SearchResult(
                text: englishText,
                ranges: [
                    englishText.range(of: "auto")!,
                    englishText.range(of: "ong")!,
                    englishText.range(of: "gli")!,
                    englishText.range(of: "what")!,
                ],
                ayah: quran.suras[3].verses[5]
            ),
            SearchResult(
                text: arabicText,
                ranges: [
                    arabicText.range(of: "خط")!,
                    arabicText.range(of: "يوض")!,
                    arabicText.range(of: "ية")!,
                    arabicText.range(of: "كمل")!,
                ],
                ayah: quran.suras[3].verses[5]
            ),
        ])

        @State var uiState = SearchUIState.search("abc")
        @State var searchState = SearchState.searching
        @State var error: Error?
        @State var autocompletions: [String] = []

        var body: some View {
            NavigationView {
                SearchViewUI(
                    error: $error,
                    uiState: uiState,
                    searchState: searchState,
                    term: "is",
                    recents: ["Recent 1", "Recent 2"],
                    populars: ["Popular 1", "Popular 2"],
                    autocompletions: autocompletions,
                    start: { },
                    search: { _ in },
                    selectSearchResult: { _ in }
                )
                .navigationTitle("Search")
                .toolbar {
                    ScrollView(.horizontal) {
                        HStack {
                            Button("Entry") {
                                uiState = .entry
                                autocompletions = []
                            }
                            Button("Autocomplete") {
                                uiState = .entry
                                autocompletions = [Self.englishText, Self.arabicText]
                            }
                            Button("Search") {
                                uiState = .search("abc")
                                searchState = .searchResult([Self.populatedResults])
                            }
                            Button("No Results") {
                                uiState = .search("abc")
                                searchState = .searchResult([])
                            }
                            Button("Loading") {
                                uiState = .search("abc")
                                searchState = .searching
                            }
                            Button("Error") { error = URLError(.notConnectedToInternet) }
                        }
                    }
                }
            }
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack {
            Preview()
        }
    }
}
