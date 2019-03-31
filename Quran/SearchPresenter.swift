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
import RIBs

protocol SearchPresentableListener: class {
    func onViewLoaded()

    func onSearchTermSelected(_ searchTerm: String)
    func onSelected(searchResult: SearchResult)
    func onSelected(autocompletion: SearchAutocompletion)
    func onSearchButtonTapped()
    func onSearchTextUpdated(to: String, isActive: Bool)
}

final class SearchPresenter: Presenter<SearchViewControllable>, SearchPresentable, SearchViewControllableListener {

    weak var listener: SearchPresentableListener?

    private var results: [SearchResult] = []
    private var autocompletions: [SearchAutocompletion] = []

    private lazy var numberFormatter = NumberFormatter()

    override init(viewController: SearchViewControllable) {
        super.init(viewController: viewController)
        viewController.listener = self
    }

    // MARK: - SearchPresenter

    func show(autocompletions: [SearchAutocompletion]) {
        self.autocompletions = autocompletions
        let strings = autocompletions.map { $0.asAttributedString() }
        viewController.show(autocompletions: strings)
    }

    func show(results: SearchResults) {
        self.results = results.items

        DispatchQueue.global().async {
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

                self.viewController.show(results: seachResultsUI, title: title)
            }
        }
    }

    func show(recents: [String], popular: [String]) {
        viewController.show(recents: recents, popular: popular)
    }

    func showLoading() {
        viewController.showLoading()
    }

    func showError(_ error: Error) {
        viewController.showError(error)
    }

    func showNoResults(for term: String) {
        let message = String(format: lAndroid("no_results"), term)
        viewController.showNoResult(message)
    }

    // MARK: - SearchViewDelegate

    func onViewLoaded() {
        listener?.onViewLoaded()
    }

    func onSearchTermSelected(_ searchTerm: String) {
        withoutDelegate {
            viewController.setSearchBarActive(true)
            viewController.updateSearchBarText(to: searchTerm)
        }
        listener?.onSearchTermSelected(searchTerm)
    }

    func onSelected(searchResultAt index: Int) {
        listener?.onSelected(searchResult: self.results[index])
    }

    func onSelected(autocompletionAt index: Int) {
        let autocompletion = self.autocompletions[index]
        withoutDelegate {
            viewController.updateSearchBarText(to: autocompletion.text)
        }
        listener?.onSelected(autocompletion: autocompletion)
    }

    func onSearchButtonTapped() {
        listener?.onSearchButtonTapped()
    }

    func onSearchTextUpdated(to text: String, isActive: Bool) {
        listener?.onSearchTextUpdated(to: text, isActive: isActive)
    }

    private func withoutDelegate(_ body: () -> Void) {
        viewController.listener = nil
        defer {
            viewController.listener = self
        }
        body()
    }
}
extension SearchAutocompletion {
    private static var arabicRegex = try! NSRegularExpression(pattern: "\\p{Arabic}") // swiftlint:disable:this force_try
    fileprivate func asAttributedString() -> NSAttributedString {
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: Theme.Kind.labelWeak.color
        ]
        let highlightedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: Theme.Kind.labelStrong.color
        ]

        let attributedString = NSMutableAttributedString(string: text, attributes: highlightedAttributes)

        let regex = SearchAutocompletion.arabicRegex
        if regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)) == nil {
            let highlightedNSRange = text.rangeAsNSRange(highlightedRange)
            attributedString.setAttributes(normalAttributes, range: highlightedNSRange)
        }
        return attributedString
    }
}

extension SearchResult {
    fileprivate func asAttributedString() -> NSAttributedString {
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: Theme.Kind.labelWeak.color
        ]
        let highlightedAttributes: [NSAttributedString.Key: Any] = [
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
