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

class SearchViewController: BaseViewController, UISearchResultsUpdating, UISearchBarDelegate, SearchView {

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return super.supportedInterfaceOrientations
        }
    }

    var router: SearchRouter? // DESIGN: Shouldn't be saved here
    weak var delegate: SearchViewDelegate?

    var searchController: UISearchController?
    lazy var searchResults: SearchResultsViewController = {
        let controller = SearchResultsViewController()
        controller.dataSource.onAutocompletionSelected = { [weak self] index in
            self?.searchController?.searchBar.resignFirstResponder()
            self?.delegate?.onSelected(autocompletionAt: index)
        }
        controller.dataSource.onResultSelected = { [weak self] index in
            self?.searchController?.searchBar.resignFirstResponder() // defensive
            self?.delegate?.onSelected(searchResultAt: index)
        }
        return controller
    }()

    override var screen: Analytics.Screen { return .search }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBOutlet weak var recents: UIStackView!
    @IBOutlet weak var recentsTitle: UILabel!
    @IBOutlet weak var popular: UIStackView!
    @IBOutlet weak var popularTitle: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.secondaryColor()

        recentsTitle.text = NSLocalizedString("searchRecentsTitle", comment: "")
        popularTitle.text = NSLocalizedString("searchPopularTitle", comment: "")

        searchController = SearchControllerWithNoCancelButton(searchResultsController: searchResults)

        searchController?.searchResultsUpdater = self
        searchController?.searchBar.delegate = self

        let searchBackgroundImage = #colorLiteral(red: 0.0716814159, green: 0.2847787611, blue: 0.3, alpha: 1).image(size: CGSize(width: 28, height: 28))?.rounded(by: 4)
        searchController?.searchBar.setSearchFieldBackgroundImage(searchBackgroundImage, for: .normal)
        searchController?.searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 8, vertical: 0)

        searchController?.searchBar.showsCancelButton = false
        searchController?.dimsBackgroundDuringPresentation = true
        searchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true

        navigationItem.titleView = searchController?.searchBar

        delegate?.onViewLoaded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = searchResults.tableView?.indexPathForSelectedRow {
            searchResults.tableView?.deselectRow(at: indexPath, animated: animated)
        }
    }

    func updateSearchResults(for searchController: UISearchController) {
        delegate?.onSearchTextUpdated(to: searchController.searchBar.text ?? "", isActive: searchController.isActive)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        delegate?.onSearchButtonTapped()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchResults.switchToAutocompletes()
    }

    // MARK: - SearchView

    func show(autocompletions: [NSAttributedString]) {
        searchResults.setAutocompletes(autocompletions)
        if searchController?.searchBar.isFirstResponder ?? false {
            searchResults.switchToAutocompletes()
        }
    }

    func show(results: [SearchResultUI], title: String?) {
        searchResults.show(results: results, title: title)
    }

    func show(recents: [String], popular: [String]) {
        updateList(stack: self.recents, title: recentsTitle, values: recents, tapSelector: #selector(onRecentOrPopularTapped(button:)))
        updateList(stack: self.popular, title: popularTitle, values: popular, tapSelector: #selector(onRecentOrPopularTapped(button:)))
    }

    func showLoading() {
        searchResults.showLoading()
    }

    func showError(_ error: Error) {
        showErrorAlert(error: error)
    }

    func showNoResult(_ message: String) {
        searchResults.showNoResult(message)
    }

    func updateSearchBarText(to text: String) {
        searchController?.searchBar.text = text
    }

    func setSearchBarActive(_ isActive: Bool) {
        searchController?.isActive = isActive
    }

    @objc
    func onRecentOrPopularTapped(button: UIButton) {
        delegate?.onSearchTermSelected(button.title(for: .normal) ?? "")
    }

    private func updateList(stack: UIStackView, title: UIView, values: [String], tapSelector: Selector) {
        title.isHidden = values.isEmpty

        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        stack.addArrangedSubview(title)
        for value in values {
            let button = UIButton(type: .system)
            button.addHeightConstraint(44)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            button.setTitle(value, for: .normal)
            button.addTarget(self, action: tapSelector, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }
}
