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
    weak var view: SearchView? { get set } // DESIGN: Shouldn't be a weak
    weak var interactor: SearchInteractor? { get set }

    func show(autocompletions: [SearchAutocompletion])
    func show(results: [SearchResult])
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

    func show(results: [SearchResult]) {
        print("Number of results", results.count)
        self.results = results

        DispatchQueue.default.async {
            let seachResultsUI = results.map {
                SearchResultUI(attributedString: $0.asAttributedString(),
                               pageNumber: self.numberFormatter.format($0.page),
                               ayahDescription: $0.ayah.localizedName)
            }
            DispatchQueue.main.async {
                self.view?.show(results: seachResultsUI)
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
        let message = String(format: NSLocalizedString("no_results", tableName: "Android", comment: ""), term)
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
        let autcompletion = self.autocompletions[index]
        withoutDelegate {
            view?.updateSearchBarText(to: autcompletion.text)
        }
        interactor?.onSelected(autocompletion: autcompletion)
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

extension NSAttributedString {
    fileprivate static let normalAttributes: [String: Any] = [
        NSFontAttributeName: UIFont.systemFont(ofSize: 14),
        NSForegroundColorAttributeName: #colorLiteral(red: 0.1333333333, green: 0.1333333333, blue: 0.1333333333, alpha: 1)
    ]
    fileprivate static let highlightedAttributes: [String: Any] = [
        NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14),
        NSForegroundColorAttributeName: #colorLiteral(red: 0.1333333333, green: 0.1326085031, blue: 0.1326085031, alpha: 1)
    ]
}

extension SearchAutocompletion {
    fileprivate func asAttributedString() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text, attributes: NSAttributedString.highlightedAttributes)
        let highlightedNSRange = text.rangeAsNSRange(highlightedRange)
        attributedString.setAttributes(NSAttributedString.normalAttributes, range: highlightedNSRange)
        return attributedString
    }
}

extension SearchResult {
    private static let style = "<style>*{font-family:-apple-system,BlinkMacSystemFont,sans-serif;font-size: 14.0;color: #444444;}b{color: #222222;}</style>" // swiftlint:disable:this line_length
    fileprivate func asAttributedString() -> NSAttributedString {
        let fullText = SearchResult.style + text
        do {
            guard let data = fullText.data(using: .utf8) else {
                return NSAttributedString(string: text)
            }
            let options: [String: Any] = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                          NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue]
            let string = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            return string
        } catch {
            Crash.recordError(error, reason: "While converting result to NSAttributedString")
            return NSAttributedString(string: text)
        }
    }
}
