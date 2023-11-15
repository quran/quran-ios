//
//  SearchViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-07-20.
//

import Combine
import Foundation
import Localization
import SwiftUI

final class SearchViewController: UIHostingController<SearchView>, UISearchResultsUpdating, UISearchBarDelegate {
    // MARK: Lifecycle

    init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
        super.init(rootView: SearchView(viewModel: viewModel))
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

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

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.placeholder = l("search.placeholder.text")
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        viewModel.$searchTerm
            .map(\.term)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchTerm in
                if searchTerm != self?.searchController.searchBar.text {
                    self?.searchController.searchBar.text = searchTerm
                }
            }
            .store(in: &cancellables)

        viewModel.resignSearchBar
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.searchController.searchBar.endEditing(true)
            }
            .store(in: &cancellables)
    }

    // MARK: - Search delegate methods

    func updateSearchResults(for searchController: UISearchController) {
        let term = searchController.searchBar.text ?? ""
        if viewModel.searchTerm.term != term {
            viewModel.searchTerm = .autocomple(term)
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        Task {
            await viewModel.search()
        }
    }

    // MARK: Private

    private var cancellables: Set<AnyCancellable> = []
    private let viewModel: SearchViewModel
    private let searchController = UISearchController(searchResultsController: nil)
}
