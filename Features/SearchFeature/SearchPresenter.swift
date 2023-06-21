//
//  SearchPresenter.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/15/17.
//

import Localization
import NoorUI
import QuranKit
import QuranText
import UIKit
import VLogging

@MainActor
final class SearchPresenter {
    // MARK: Lifecycle

    init(interactor: SearchInteractor) {
        self.interactor = interactor
        interactor.presenter = self
    }

    // MARK: Internal

    weak var viewController: SearchViewController?

    // MARK: - SearchPresenter

    func resetSearchBar() {
        viewController?.updateSearchBarText(to: "")
        viewController?.setSearchBarActive(false)
    }

    func show(autocompletions: [SearchAutocompletion]) {
        self.autocompletions = autocompletions
        let strings = autocompletions.map { $0.asAttributedString() }
        viewController?.show(autocompletions: strings)
    }

    func show(results: [SearchResults]) {
        self.results = results

        DispatchQueue.global().async {
            let sections = results.map { result -> SearchResultSectionUI in
                let title: String
                switch result.source {
                case .translation(let translation): title = translation.translationName
                case .quran: title = (Bundle.main.localizedInfoDictionary?["CFBundleName"] as? String) ?? "Quran"
                }
                let seachResultsUI = result.items.map {
                    SearchResultUI(
                        attributedString: $0.asAttributedString(),
                        pageNumber: $0.ayah.page.localizedNumber,
                        ayahDescription: attributedString(
                            of: $0.ayah.localizedName,
                            arabicSuraName: $0.ayah.sura.arabicSuraName,
                            fontSize: 15
                        )
                    )
                }
                return SearchResultSectionUI(title: title, items: seachResultsUI)
            }
            DispatchQueue.main.async {
                self.viewController?.show(results: sections)
            }
        }
    }

    func show(recents: [String], popular: [String]) {
        viewController?.show(recents: recents, popular: popular)
    }

    func showLoading() {
        viewController?.showLoading()
    }

    func showError(_ error: Error) {
        viewController?.showError(error)
    }

    func showNoResults(for term: String) {
        let message = lFormat("no_results", table: .android, term)
        viewController?.showNoResult(message)
    }

    // MARK: - SearchViewDelegate

    func onViewLoaded() {
        interactor.onViewLoaded()
    }

    func onSearchTermSelected(_ searchTerm: String) {
        logger.info("Search: Recent search selected '\(searchTerm)'")
        viewController?.setSearchBarActive(true)
        viewController?.updateSearchBarText(to: searchTerm)
        interactor.search(term: searchTerm)
    }

    func onSelected(searchResultAt index: IndexPath) {
        let section = results[index.section]
        interactor.onSelected(searchResult: section.items[index.item], source: section.source)
    }

    func onSelected(autocompletionAt index: Int) {
        let autocompletion = autocompletions[index]
        viewController?.updateSearchBarText(to: autocompletion.text)
        interactor.search(term: autocompletion.text)
    }

    func onSearchButtonTapped() {
        interactor.onSearchButtonTapped()
    }

    func onSearchTextUpdated(to text: String, isActive: Bool) {
        interactor.onSearchTextUpdated(to: text, isActive: isActive)
    }

    // MARK: Private

    private let interactor: SearchInteractor
    private var results: [SearchResults] = []
    private var autocompletions: [SearchAutocompletion] = []
}

extension SearchAutocompletion {
    // Regex to see if the string contains any Arabic letter
    private static var arabicRegex = try! NSRegularExpression(pattern: #"\p{Arabic}"#) // swiftlint:disable:this force_try
    func asAttributedString() -> NSAttributedString {
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel,
        ]
        let highlightedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
        ]

        let attributedString = NSMutableAttributedString(string: text, attributes: highlightedAttributes)

        if let highlightedRange {
            let range = NSRange(text.startIndex ..< text.endIndex, in: text)
            if Self.arabicRegex.firstMatch(in: text, options: [], range: range) == nil {
                attributedString.setAttributes(normalAttributes, range: highlightedRange)
            }
        }
        return attributedString
    }
}

extension SearchResult {
    func asAttributedString() -> NSAttributedString {
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
        ]
        let highlightedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .black),
        ]

        // split the components on <b> and construct NSAttirbutedString for substring ourselves
        // instead of loading HTML directly improves the search significantly
        let textComponents = text.components(separatedBy: "<b>")
        let attributedString = NSMutableAttributedString()
        for (offset, text) in textComponents.enumerated() {
            let attributes = offset % 2 == 0 ? normalAttributes : highlightedAttributes
            let substring = NSAttributedString(string: text, attributes: attributes)
            attributedString.append(substring)
        }
        return attributedString
    }
}
