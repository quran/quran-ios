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
import Localization
import NoorUI
import UIKit
import UIx

struct SearchResultUI {
    let attributedString: NSAttributedString
    let pageNumber: String
    let ayahDescription: NSAttributedString
}

struct SearchResultSectionUI {
    let title: String
    let items: [SearchResultUI]
}

class SearchResultsDataSource: SegmentedDataSource {
    // MARK: Lifecycle

    override init() {
        super.init()
        add(loading)
        add(autocomplete)
        add(noResults)

        autocomplete.setDidSelect { [weak self] _, _, indexPath in
            self?.onAutocompletionSelected?(indexPath.item)
        }

        results.didSelectBlock = { [weak self] indexPath in
            self?.onResultSelected?(indexPath)
        }
    }

    // MARK: Internal

    weak var controller: UIViewController?

    var onResultSelected: ((IndexPath) -> Void)?
    var onAutocompletionSelected: ((Int) -> Void)?

    override var selectedDataSource: DataSource? {
        didSet {
            ds_reusableViewDelegate?.ds_reloadData()
            ds_reusableViewDelegate?.ds_scrollView.isUserInteractionEnabled = selectedDataSource !== loading
            ds_reusableViewDelegate?.asTableView()?.scrollToTop(animated: false)
        }
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

    func switchToResults(_ items: [SearchResultSectionUI]) {
        results.results = items
        headerTitles = items.map { result in
            lFormat("searchResultTitle", result.title, result.items.count)
        }
        selectedDataSource = results
    }

    func switchToNoResults(_ message: String) {
        noResults.items = [message]
        selectedDataSource = noResults
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < headerTitles.count else {
            return nil
        }
        guard let controller else {
            return nil
        }
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: HostingTableViewHeaderFooterView<TableHeaderView>.ds_reuseId)
            as? HostingTableViewHeaderFooterView<TableHeaderView>
        let header = TableHeaderView(title: headerTitles[section])
        view?.set(rootView: header, parentController: controller)
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        selectedDataSource === results ? UITableView.automaticDimension : 0
    }

    // MARK: Private

    private let loading = FullScreenLoadingDataSource()
    private let autocomplete = SearchAutocompletionDataSource()
    private let results = SectionedSearchResultDataSource(sectionType: .multi)
    private let noResults = NoSearchResultDataSource()

    private var headerTitles: [String] = []
}

private class SearchAutocompletionDataSource: BasicDataSource<NSAttributedString, SearchAutocompleteTableViewCell> {
    // MARK: Internal

    override func ds_collectionView(
        _ collectionView: GeneralCollectionView,
        configure cell: SearchAutocompleteTableViewCell,
        with item: NSAttributedString,
        at indexPath: IndexPath
    ) {
        cell.label?.attributedText = item
        cell.icon?.image = image
        cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 0, height: 44)
    }

    // MARK: Private

    private let image = #imageLiteral(resourceName: "search-128").scaled(toHeight: 18)?.withRenderingMode(.alwaysTemplate)
}

private class SectionedSearchResultDataSource: CompositeDataSource {
    var didSelectBlock: ((IndexPath) -> Void)?

    var results: [SearchResultSectionUI] = [] {
        didSet {
            removeAllDataSources()
            for section in results {
                let ds = SearchResultDataSource()
                ds.items = section.items
                add(ds)
            }
        }
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectBlock?(indexPath)
    }
}

private class SearchResultDataSource: BasicDataSource<SearchResultUI, SearchResultTableViewCell> {
    override func ds_collectionView(
        _ collectionView: GeneralCollectionView,
        configure cell: SearchResultTableViewCell,
        with item: SearchResultUI,
        at indexPath: IndexPath
    ) {
        cell.resultLabel.attributedText = item.attributedString
        cell.pageNumber.text = item.pageNumber
        cell.ayahDescription.attributedText = item.ayahDescription
        cell.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = item(at: indexPath)
        let size = item.attributedString.stringSize(constrainedToWidth: collectionView.ds_scrollView.bounds.width - 25)
        return CGSize(width: 0, height: size.height + 46)
    }
}

private class NoSearchResultDataSource: BasicDataSource<String, SearchNoResultTableViewCell> {
    override func ds_collectionView(
        _ collectionView: GeneralCollectionView,
        configure cell: SearchNoResultTableViewCell,
        with item: String,
        at indexPath: IndexPath
    ) {
        cell.descriptionLabel.text = item
        cell.separatorInset = UIEdgeInsets(top: 0, left: collectionView.ds_scrollView.bounds.width, bottom: 0, right: 0)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let scrollView = collectionView.ds_scrollView
        return CGSize(
            width: scrollView.bounds.width - (scrollView.contentInset.left + scrollView.contentInset.right),
            height: scrollView.bounds.height - (scrollView.contentInset.top + scrollView.contentInset.bottom)
        )
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        false
    }
}
