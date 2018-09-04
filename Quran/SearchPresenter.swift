//
//  SearchPresenter.swift
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

protocol SearchPresenter: class {
    var view: SearchView? { get set } // DESIGN: Shouldn't be a weak
    var interactor: SearchInteractor? { get set }

    func show(autocompletions: [SearchAutocompletion])
    func show(results: SearchResults)
    func show(recents: [String], popular: [String])

    func showLoading()
    func showError(_ error: Error)
    func showNoResults(for term: String)
}

class DefaultSearchPresenter: SearchPresenter, SearchViewDelegate {

    weak var view: SearchView? // DESIGN: Shouldn't be a weak
    weak var interactor: SearchInteractor?

    private var results: [SearchResult] = []
    private var autocompletions: [SearchAutocompletion] = []

    private lazy var numberFormatter = NumberFormatter()

    // MARK: - SearchPresenter

    func show(autocompletions: [SearchAutocompletion]) {
        self.autocompletions = autocompletions
        let strings = autocompletions.map { $0.asAttributedString() }
        view?.show(autocompletions: strings)
    }

    func show(results: SearchResults) {
        self.results = results.items

        DispatchQueue.default.async {
            let seachResultsUI = results.items.map {
                SearchResultUI(attributedString: $0.asAttributedString(),
                               pageNumber: self.numberFormatter.format($0.page),
                               ayahDescription: $0.ayah.localizedName)
            }
            DispatchQueue.main.async {
                let title: String?
                switch results.source {
                case .none: title = nil
                case .translation(let translation): title = translation.translationName
                case .quran: title = Bundle.main.localizedInfoDictionary?["CFBundleName"] as? String
                }

                self.view?.show(results: seachResultsUI, title: title)
            }
        }
    }

    func show(recents: [String], popular: [String]) {
        view?.show(recents: recents, popular: popular)
    }

    func showLoading() {
        view?.showLoading()
    }

    func showError(_ error: Error) {
        view?.showError(error)
    }

    func showNoResults(for term: String) {
        let message = String(format: lAndroid("no_results"), term)
        view?.showNoResult(message)
    }

    // MARK: - SearchViewDelegate

    func onViewLoaded() {
        interactor?.onViewLoaded()
    }

    func onSearchTermSelected(_ searchTerm: String) {
        withoutDelegate {
            view?.setSearchBarActive(true)
            view?.updateSearchBarText(to: searchTerm)
        }
        interactor?.onSearchTermSelected(searchTerm)
    }

    func onSelected(searchResultAt index: Int) {
        interactor?.onSelected(searchResult: self.results[index])
    }

    func onSelected(autocompletionAt index: Int) {
        let autocompletion = self.autocompletions[index]
        withoutDelegate {
            view?.updateSearchBarText(to: autocompletion.text)
        }
        interactor?.onSelected(autocompletion: autocompletion)
    }

    func onSearchButtonTapped() {
        interactor?.onSearchButtonTapped()
    }

    func onSearchTextUpdated(to text: String, isActive: Bool) {
        interactor?.onSearchTextUpdated(to: text, isActive: isActive)
    }

    private func withoutDelegate(_ body: () -> Void) {
        view?.delegate = nil
        defer {
            view?.delegate = self
        }
        body()
    }
}
extension SearchAutocompletion {
    fileprivate func asAttributedString() -> NSAttributedString {
        let normalAttributes: [NSAttributedStringKey: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: Theme.Kind.labelWeak.color
        ]
        let highlightedAttributes: [NSAttributedStringKey: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: Theme.Kind.labelStrong.color
        ]

        let attributedString = NSMutableAttributedString(string: text, attributes: highlightedAttributes)
        let highlightedNSRange = text.rangeAsNSRange(highlightedRange)
        attributedString.setAttributes(normalAttributes, range: highlightedNSRange)
        return attributedString
    }
}

extension SearchResult {
    fileprivate func asAttributedString() -> NSAttributedString {
        let normalAttributes: [NSAttributedStringKey: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: Theme.Kind.labelWeak.color
        ]
        let highlightedAttributes: [NSAttributedStringKey: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: Theme.Kind.labelStrong.color
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
