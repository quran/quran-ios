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
import RIBs
import RxCocoa
import RxSwift

protocol SearchRouting: ViewableRouting {
}

protocol SearchPresentable: class {
    var listener: SearchPresentableListener? { get set }

    func show(autocompletions: [SearchAutocompletion])
    func show(results: SearchResults)
    func show(recents: [String], popular: [String])

    func showLoading()
    func showError(_ error: Error)
    func showNoResults(for term: String)
}

protocol SearchListener: class {
    func navigateTo(quranPage: Int, highlightingAyah: AyahNumber)
}

final class SearchInteractor: PresentableInteractor<SearchPresentable>, SearchInteractable, SearchPresentableListener {

    weak var router: SearchRouting?
    weak var listener: SearchListener?

    private let disposeBag = DisposeBag()
    private let searchTerm = Variable("")
    private let startSearching = EventStream<Void>()

    private let persistence: SimplePersistence
    private let recentsService: SearchRecentsService

    private var source: SearchResult.Source?

    init(
        presenter: SearchPresentable,
        persistence: SimplePersistence,
        autocompleteService: SearchAutocompletionService,
        searchService: SearchService,
        recentsService: SearchRecentsService) {
        self.persistence = persistence
        self.recentsService = recentsService
        super.init(presenter: presenter)
        presenter.listener = self

        // loading search
        let loading = ActivityIndicator()
        loading
            .filter { $0 }
            .drive(onNext: { [weak self] _ in
                self?.presenter.showLoading()
            }).disposed(by: disposeBag)

        // auto completion
        searchTerm
            .asDriver()
            .throttle(0.3)
            .distinctUntilChanged()
            .flatMapLatest { query -> Driver<[SearchAutocompletion]> in
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    return .just([])
                } else {
                    return autocompleteService
                        .autocomplete(term: query)
                        .asDriver(onErrorJustReturn: [])
                }
            }.drive(onNext: { [weak self] (completions) in
                self?.presenter.show(autocompletions: completions)
            }).disposed(by: disposeBag)

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
                case .success(let results):
                    self?.source = results.source

                    Analytics.shared.searching(for: query, source: results.source, resultsCount: results.items.count)
                    if results.items.isEmpty {
                        self?.presenter.showNoResults(for: query)
                    } else {
                        self?.presenter.show(results: results)
                    }
                case .failure(let error):
                    self?.source = nil
                    self?.presenter.show(results: SearchResults(source: .none, items: []))
                    self?.presenter.showError(error)
                }
                self?.recentsService.addToRecents(query)
                self?.recentsUpdated()
            }).disposed(by: disposeBag)
    }

    private func recentsUpdated() {
        presenter.show(recents: recentsService.getRecents(), popular: recentsService.getPopularTerms())
    }

    func onViewLoaded() {
        recentsUpdated()
    }

    func onSearchTermSelected(_ term: String) {
        // update the model
        searchTerm.value = term

        // start searching
        startSearching.trigger(())
    }

    func onSelected(searchResult: SearchResult) {
        // show translation if not an active translation
        switch source {
        case .none, .some(.quran), .some(.none): break
        case .some(.translation(let translation)):
            persistence.setValue(true, forKey: .showQuranTranslationView)
            var translationIds = persistence.valueForKey(.selectedTranslations)
            if !translationIds.contains(translation.id) {
                translationIds.append(translation.id)
                persistence.setValue(translationIds, forKey: .selectedTranslations)
            }
        }


        // navigate to the selected page
        Analytics.shared.openingQuran(from: .searchResults)
        listener?.navigateTo(quranPage: searchResult.page, highlightingAyah: searchResult.ayah)
    }

    func onSelected(autocompletion: SearchAutocompletion) {
        // update the model
        searchTerm.value = autocompletion.text

        // start searching
        startSearching.trigger(())
    }

    func onSearchButtonTapped() {
        // start searching
        startSearching.trigger(())
    }

    func onSearchTextUpdated(to term: String, isActive: Bool) {
        // update the model
        searchTerm.value = term
    }
}
