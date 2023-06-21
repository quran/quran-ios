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

import Localization
import NoorUI
import UIKit

final class SearchViewController: BaseViewController, UISearchResultsUpdating, UISearchBarDelegate {
    // MARK: Lifecycle

    init(presenter: SearchPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        presenter.viewController = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    lazy var searchController: UISearchController = UISearchController(searchResultsController: searchResults)
    lazy var searchResults: SearchResultsViewController = {
        let controller = SearchResultsViewController()
        controller.dataSource.onAutocompletionSelected = { [weak self] index in
            self?.searchController.searchBar.resignFirstResponder()
            self?.presenter.onSelected(autocompletionAt: index)
        }
        controller.dataSource.onResultSelected = { [weak self] index in
            self?.searchController.searchBar.resignFirstResponder() // defensive
            self?.presenter.onSelected(searchResultAt: index)
        }
        return controller
    }()

    @IBOutlet var recents: UIStackView!
    @IBOutlet var recentsTitle: UILabel!
    @IBOutlet var popular: UIStackView!
    @IBOutlet var popularTitle: UILabel!

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return super.supportedInterfaceOrientations
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = lAndroid("menu_search")
        navigationItem.largeTitleDisplayMode = .never

        recentsTitle.text = l("searchRecentsTitle")
        popularTitle.text = l("searchPopularTitle")

        searchController.searchBar.placeholder = l("searchPlaceholder")
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        definesPresentationContext = true

        presenter.onViewLoaded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if let indexPath = searchResults.tableView?.indexPathForSelectedRow {
            searchResults.tableView?.deselectRow(at: indexPath, animated: animated)
        }
    }

    func updateSearchResults(for searchController: UISearchController) {
        presenter.onSearchTextUpdated(to: searchController.searchBar.text ?? "", isActive: searchController.isActive)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        presenter.onSearchButtonTapped()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchResults.switchToAutocompletes()
    }

    // MARK: - SearchView

    func show(autocompletions: [NSAttributedString]) {
        searchResults.setAutocompletes(autocompletions)
        if searchController.searchBar.isFirstResponder {
            searchResults.switchToAutocompletes()
        }
    }

    func show(results: [SearchResultSectionUI]) {
        searchResults.show(results: results)
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
        searchController.searchBar.text = text
    }

    func setSearchBarActive(_ isActive: Bool) {
        searchController.isActive = isActive
    }

    @objc
    func onRecentOrPopularTapped(button: UIButton) {
        presenter.onSearchTermSelected(button.title(for: .normal) ?? "")
    }

    // MARK: Private

    private let presenter: SearchPresenter

    private func updateList(stack: UIStackView, title: UIView, values: [String], tapSelector: Selector) {
        title.isHidden = values.isEmpty

        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        stack.addArrangedSubview(title)
        for value in values {
            let button = UIButton(type: .system)
            button.vc.height(by: 44)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            button.setTitle(value, for: .normal)
            button.addTarget(self, action: tapSelector, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }
}
