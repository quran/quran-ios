//
//  SearchViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
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

class SearchViewController: BaseTableViewController, UISearchResultsUpdating, UISearchBarDelegate {

    let searchController = UISearchController(searchResultsController: nil)

    override var screen: Analytics.Screen { return .search }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.secondaryColor()

        let searchBackgroundImage = #colorLiteral(red: 0.0716814159, green: 0.2847787611, blue: 0.3, alpha: 1).image(size: CGSize(width: 28, height: 28))?.rounded(by: 4)
        searchController.searchBar.setSearchFieldBackgroundImage(searchBackgroundImage, for: .normal)
        searchController.searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 8, vertical: 0)

        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = true
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true

        navigationItem.titleView = searchController.searchBar
    }

    func updateSearchResults(for searchController: UISearchController) {
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
