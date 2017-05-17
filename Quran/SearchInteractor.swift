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
import RxCocoa
import RxSwift

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

    private let disposeBag = DisposeBag()
    private let searchTerm = Variable("")
    private let startSearching = EventStream<Void>()

    private let recentsService: SearchRecentsService

    init(autocompleteService: SearchAutocompletionService, searchService: SearchService, recentsService: SearchRecentsService) {
        self.recentsService = recentsService

        // loading search
        let loading = ActivityIndicator()
        loading
            .filter { $0 }
            .drive(onNext: { [weak self] _ in
                self?.presenter?.showLoading()
            }).addDisposableTo(disposeBag)

        // auto completion
        searchTerm
            .asDriver()
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .throttle(0.3)
            .distinctUntilChanged()
            .flatMapLatest { query in
                autocompleteService
                    .autocompletes(for: query)
                    .asDriver(onErrorJustReturn: [])
            }.drive(onNext: { [weak self] (completions) in
                self?.presenter?.show(autocompletions: completions)
            }).addDisposableTo(disposeBag)

        // search
        startSearching
            .asDriver()
            .withLatestFrom(searchTerm.asDriver())
            .flatMapLatest { query in
                searchService
                    .search(for: query)
                    .trackActivity(loading)
                    .map { (Result.success($0), query) }
                    .asDriver(onErrorTransform: { (Result.failure($0), query) })
            }.drive(onNext: { [weak self] (result, query) in
                switch result {
                case .success(let results): self?.presenter?.show(results: results)
                case .failure(let error)  : self?.presenter?.showError(error)
                }
                self?.recentsService.addToRecents(query)
                self?.recentsUpdated()
            }).addDisposableTo(disposeBag)
    }

    private func recentsUpdated() {
        presenter?.show(recents: recentsService.getRecents(), popular: recentsService.getPopularTerms())
    }

    func onViewLoaded() {
        recentsUpdated()
    }

    func onSearchTermSelected(_ term: String) {
        // update the model
        searchTerm.value = term

        // start searching
        startSearching.trigger()
    }

    func onSelected(searchResult: SearchResult) {
        // navigate to the selected page
        router?.navigateTo(quranPage: searchResult.page, highlightingAyah: searchResult.ayah)
    }

    func onSelected(autocompletion: SearchAutocompletion) {
        // update the model
        searchTerm.value = autocompletion.text

        // start searching
        startSearching.trigger()
    }

    func onSearchButtonTapped() {
        // start searching
        startSearching.trigger()
    }

    func onSearchTextUpdated(to term: String, isActive: Bool) {
        // update the model
        searchTerm.value = term
    }
}
