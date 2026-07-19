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
import VLogging

final class SearchViewController: UIViewController, UISearchBarDelegate {
    // MARK: Lifecycle

    init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
        searchResultsViewController = UIHostingController(rootView: SearchView(viewModel: viewModel))
        super.init(nibName: nil, bundle: nil)
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

        addFullScreenChild(searchResultsViewController)

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.placeholder = l("search.placeholder.text")
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        viewModel.$searchTerm
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchTerm in
                self?.searchController.searchBar.text = searchTerm
            }
            .store(in: &cancellables)

        viewModel.$keyboardState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .closed:
                    self?.searchController.searchBar.endEditing(true)
                case .open:
                    self?.searchController.searchBar.becomeFirstResponder()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Search delegate methods

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        logger.info("[Search] textDidChange to \(searchText)")
        viewModel.autocomplete(searchText)
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        logger.info("[Search] searchBarTextDidBeginEditing \(searchBar.text ?? "")")
        viewModel.keyboardState = .open
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        logger.info("[Search] searchBarTextDidEndEditing \(searchBar.text ?? "")")
        viewModel.keyboardState = .closed
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        logger.info("[Search] searchBarSearchButtonClicked \(searchBar.text ?? "")")
        viewModel.searchForUserTypedTerm()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        logger.info("[Search] searchBarCancelButtonClicked")
        viewModel.reset()
    }

    // MARK: Private

    private var cancellables: Set<AnyCancellable> = []
    private let viewModel: SearchViewModel
    private let searchController = UISearchController(searchResultsController: nil)
    private let searchResultsViewController: UIHostingController<SearchView>
}
