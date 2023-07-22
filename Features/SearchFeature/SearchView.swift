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
            type: viewModel.searchType,
            term: viewModel.searchTerm.term,
            recents: viewModel.recents,
            populars: viewModel.populars,
            autocompletions: viewModel.autocompletions,
            searchResults: viewModel.searchResults,
            start: { await viewModel.start() },
            search: { await viewModel.search(searchTerm: $0) },
            selectSearchResult: { viewModel.select(searchResult: $0.result, source: $0.source) }
        )
    }
}

private struct SearchViewUI: View {
    @Binding var error: Error?

    let type: SearchUIType

    let term: String
    let recents: [String]
    let populars: [String]
    let autocompletions: [String]
    let searchResults: [SearchResults]

    let start: AsyncAction
    let search: AsyncItemAction<String>
    let selectSearchResult: ItemAction<(result: SearchResult, source: SearchResults.Source)>

    var body: some View {
        Group {
            switch type {
            case .entry:
                entry
            case .autocomplete:
                autocompletionsView
            case .loading:
                NoorList {
                    LoadingView()
                }
            case .searchResults:
                searchResultsView
            }
        }
        .task(start)
        .errorAlert(error: $error)
    }

    @ViewBuilder
    var searchResultsView: some View {
        if !searchResults.isEmpty {
            NoorList {
                ForEach(searchResults) { result in
                    let plainTitle = title(of: result)
                    let title = lFormat("searchResultTitle", plainTitle, result.items.count)
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
            NoorSection(title: l("searchRecentsTitle"), recents.map(SelfIdentifiable.init)) { item in
                NoorListItem(
                    image: .init(.search),
                    title: .text(item.value)
                ) {
                    await search(item.value)
                }
            }

            NoorSection(title: l("searchPopularTitle"), populars.map(SelfIdentifiable.init)) { item in
                NoorListItem(
                    image: .init(.search),
                    title: .text(item.value)
                ) {
                    await search(item.value)
                }
            }
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

        @State var results = [populatedResults]
        @State var type = SearchUIType.searchResults
        @State var error: Error?

        var body: some View {
            NavigationView {
                SearchViewUI(
                    error: $error,
                    type: type,
                    term: "is",
                    recents: ["Recent 1", "Recent 2"],
                    populars: ["Popular 1", "Popular 2"],
                    autocompletions: [Self.englishText, Self.arabicText],
                    searchResults: results,
                    start: { },
                    search: { _ in },
                    selectSearchResult: { _ in }
                )
                .navigationTitle("Search")
                .toolbar {
                    ScrollView(.horizontal) {
                        HStack {
                            Button("Entry") { type = .entry }
                            Button("Autocomplete") { type = .autocomplete }
                            Button("Search") {
                                type = .searchResults
                                results = [Self.populatedResults]
                            }
                            Button("No Results") {
                                type = .searchResults
                                results = []
                            }
                            Button("Loading") { type = .loading }
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
