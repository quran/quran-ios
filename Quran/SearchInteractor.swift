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

protocol SearchInteractor: class {
    weak var router: SearchRouter? { get set }
    weak var presenter: SearchPresenter? { get set }

    func onViewLoaded()

    func onSearchTermSelected(_ searchTerm: String)
    func onSelected(searchResult: SearchResult)
    func onSelected(autocompletion: SearchAutocompletion)
    func onSearchButtonTapped()
    func onSearchTextUpdated(to: String, isActive: Bool)
}

class DefaultSearchInteractor: SearchInteractor {

    weak var router: SearchRouter?
    weak var presenter: SearchPresenter?

    func onViewLoaded() {
        presenter?.show(recents: ["Recent 1", "Recent 2", "very old recent"], popular: ["Popular 1", "Popular 2", "Way popular", "Way popular 2"])
    }

    func onSearchTermSelected(_ searchTerm: String) {
        // TODO: update the search term model

        // start searching
        search()
    }

    func onSelected(searchResult: SearchResult) {
        // TODO: update the recents

        // navigate to the selected page
        router?.navigateTo(quranPage: searchResult.page, highlightingAyah: searchResult.ayah)
    }

    func onSelected(autocompletion: SearchAutocompletion) {
        // TODO: update the search term model

        // start searching
        search()
    }

    func onSearchButtonTapped() {
        // start searching
        search()
    }

    func onSearchTextUpdated(to term: String, isActive: Bool) {
        // TODO: update the model

        // get some auto complete results
        DispatchQueue.main.async {
            self.presenter?.show(autocompletions: [
                SearchAutocompletion(text: term + "test", highlightedRange: (term.startIndex..<term.endIndex)),
                SearchAutocompletion(text: term + "popular", highlightedRange: (term.startIndex..<term.endIndex)),
                SearchAutocompletion(text: term + "something to the other", highlightedRange: (term.startIndex..<term.endIndex))])
        }
    }

    private func search() {
        presenter?.showLoading()

        // get some auto complete results
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let long = "some search 1, to the end of it, but very long and that is long enough. I don't know let's check it. But we are not sure, let's use 3rd line"
            self.presenter?.show(results: [
                SearchResult(text: long, ayah: AyahNumber(sura: 2, ayah: 78), page: 12, highlightedRanges: [long.range(of: "search 1")!, long.range(of: "is long enough")!]),
                SearchResult(text: "some search 2", ayah: AyahNumber(sura: 1, ayah: 1), page: 1, highlightedRanges: []),
                SearchResult(text: "some search 3", ayah: AyahNumber(sura: 2, ayah: 6), page: 3, highlightedRanges: [])
                ])
        }
    }
}
