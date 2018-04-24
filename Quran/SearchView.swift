//
//  SearchView.swift
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

protocol SearchViewDelegate: class {
    func onViewLoaded()

    func onSearchTermSelected(_ searchTerm: String)
    func onSelected(searchResultAt index: Int)
    func onSelected(autocompletionAt index: Int)

    func onSearchButtonTapped()

    func onSearchTextUpdated(to text: String, isActive: Bool)
}

protocol SearchView: class {
    var delegate: SearchViewDelegate? { get set }

    func show(autocompletions: [NSAttributedString])
    func show(results: [SearchResultUI], title: String?)
    func show(recents: [String], popular: [String])

    func showLoading()
    func showError(_ error: Error)
    func showNoResult(_ message: String)

    func updateSearchBarText(to text: String)
    func setSearchBarActive(_ isActive: Bool)
}
