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

    var onResultSelected: ((Int) -> Void)?
    var onAutocompletionSelected: ((Int) -> Void)?

    override var selectedDataSource: DataSource? {
        didSet {
            ds_reusableViewDelegate?.ds_reloadData()
            ds_reusableViewDelegate?.ds_scrollView.isUserInteractionEnabled = selectedDataSource !== loading
        }
    }

    override init() {
        super.init()
        add(loading)
        add(autocomplete)

        let autocompleteSelection = BlockSelectionHandler<NSAttributedString, UITableViewCell>()
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

    func switchToAutocomplete(with items: [NSAttributedString]) {
        autocomplete.items = items
        selectedDataSource = autocomplete
    }

    func switchToResults(with items: [SearchResultUI]) {
        results.items = items
        selectedDataSource = results
    }
}

private class SearchAutocompletionDataSource: BasicDataSource<NSAttributedString, UITableViewCell> {

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: UITableViewCell,
                                    with item: NSAttributedString,
                                    at indexPath: IndexPath) {
        cell.textLabel?.attributedText = item
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
