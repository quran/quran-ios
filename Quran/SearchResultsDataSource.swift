//
//  SearchResultsDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/16/17.
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
import GenericDataSources

struct SearchResultUI {
    let attributedString: NSAttributedString
    let pageNumber: String
    let ayahDescription: String
}

class SearchResultsDataSource: SegmentedDataSource {

    private let loading = FullScreenLoadingDataSource()
    private let autocomplete = SearchAutocompletionDataSource()
    private let results = SearchResultDataSource()
    private let noResults = NoSearchResultDataSource()

    var onResultSelected: ((Int) -> Void)?
    var onAutocompletionSelected: ((Int) -> Void)?

    private var headerTitle: String?

    override var selectedDataSource: DataSource? {
        didSet {
            ds_reusableViewDelegate?.ds_reloadData()
            ds_reusableViewDelegate?.ds_scrollView.isUserInteractionEnabled = selectedDataSource !== loading
            ds_reusableViewDelegate?.asTableView()?.scrollToTop(animated: false)
        }
    }

    override init() {
        super.init()
        add(loading)
        add(autocomplete)
        add(noResults)

        let autocompleteSelection = BlockSelectionHandler<NSAttributedString, SearchAutocompleteTableViewCell>()
        autocompleteSelection.didSelectBlock = { [weak self] (_, _, indexPath) in
            self?.onAutocompletionSelected?(indexPath.item)
        }
        autocomplete.setSelectionHandler(autocompleteSelection)

        let resultsSelection = BlockSelectionHandler<SearchResultUI, SearchResultTableViewCell>()
        resultsSelection.didSelectBlock = { [weak self] (_, _, indexPath) in
            self?.onResultSelected?(indexPath.item)
        }
        results.setSelectionHandler(resultsSelection)
    }

    func switchToLoading() {
        selectedDataSource = loading
    }

    func setAutocompletes(_ items: [NSAttributedString]) {
        autocomplete.items = items
    }

    func switchToAutocompletes() {
        selectedDataSource = autocomplete
    }

    func switchToResults(with items: [SearchResultUI], title: String?) {
        results.items = items
        headerTitle = title
        selectedDataSource = results
    }

    func switchToNoResults(_ message: String) {
        noResults.items = [message]
        selectedDataSource = noResults
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerTitle = headerTitle else {
            return nil
        }
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: JuzTableViewHeaderFooterView.ds_reuseId) as? JuzTableViewHeaderFooterView
        view?.titleLabel.text = headerTitle
        view?.subtitleLabel.isHidden = true
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return selectedDataSource === results ? 44 : 0
    }
}

private class SearchAutocompletionDataSource: BasicDataSource<NSAttributedString, SearchAutocompleteTableViewCell> {
    private let image = #imageLiteral(resourceName: "search-128").scaled(toHeight: 18)?.withRenderingMode(.alwaysTemplate)

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: SearchAutocompleteTableViewCell,
                                    with item: NSAttributedString,
                                    at indexPath: IndexPath) {
        cell.label?.attributedText = item
        cell.icon?.image = image
        cell.icon?.kind = .labelWeak
        cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 0, height: 44)
    }
}

private class SearchResultDataSource: BasicDataSource<SearchResultUI, SearchResultTableViewCell> {

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: SearchResultTableViewCell,
                                    with item: SearchResultUI,
                                    at indexPath: IndexPath) {
        cell.resultLabel.attributedText = item.attributedString
        cell.pageNumber.text = item.pageNumber
        cell.ayahDescription.text = item.ayahDescription
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = self.item(at: indexPath)
        let size = item.attributedString.stringSize(constrainedToWidth: collectionView.ds_scrollView.bounds.width - 25)
        return CGSize(width: 0, height: size.height + 46)
    }
}

private class NoSearchResultDataSource: BasicDataSource<String, SearchNoResultTableViewCell> {

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: SearchNoResultTableViewCell,
                                    with item: String, at indexPath: IndexPath) {
        cell.descriptionLabel.text = item
        cell.separatorInset = UIEdgeInsets(top: 0, left: collectionView.ds_scrollView.bounds.width, bottom: 0, right: 0)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let scrollView = collectionView.ds_scrollView
        return CGSize(width: scrollView.bounds.width - (scrollView.contentInset.left + scrollView.contentInset.right),
                      height: scrollView.bounds.height - (scrollView.contentInset.top + scrollView.contentInset.bottom))
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}
