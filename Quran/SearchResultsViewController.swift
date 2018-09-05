//
//  SearchResultsViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/17.
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

import UIKit

class SearchResultsViewController: BaseTableViewController {

    let dataSource = SearchResultsDataSource()

    override var screen: Analytics.Screen { return .searchResults }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.ds_register(cellNib: SearchAutocompleteTableViewCell.self)
        tableView.ds_register(cellClass: FullScreenLoadingTableViewCell.self)
        tableView.ds_register(cellNib: SearchResultTableViewCell.self)
        tableView.ds_register(cellNib: SearchNoResultTableViewCell.self)
        tableView.ds_register(headerFooterClass: JuzTableViewHeaderFooterView.self)
        tableView.ds_useDataSource(dataSource)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        clearsSelectionOnViewWillAppear = true
    }

    func showLoading() {
        dataSource.switchToLoading()
    }

    func setAutocompletes(_ autocompletes: [NSAttributedString]) {
        dataSource.setAutocompletes(autocompletes)
    }

    func switchToAutocompletes() {
        dataSource.switchToAutocompletes()
    }

    func show(results: [SearchResultUI], title: String?) {
        dataSource.switchToResults(with: results, title: title)
    }

    func showNoResult(_ message: String) {
        dataSource.switchToNoResults(message)
    }
}
