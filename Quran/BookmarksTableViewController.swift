//
//  BookmarksTableViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/16.
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
import UIKit

protocol BookmarksPresentableListener: class {
    func navigateTo(quranPage: Int, lastPage: LastPage?)
}

class BookmarksTableViewController: BaseTableBasedViewController, EditControllerDelegate, BookmarkDataSourceDelegate, BookmarksPresentable, BookmarksViewControllable {

    weak var listener: BookmarksPresentableListener?

    override var screen: Analytics.Screen { return .bookmarks }

    let editController = EditController(usesRightBarButton: true)
    let dataSource: BookmarksDataSource = BookmarksDataSource(type: .multi)
    let lastPageDS: LastPageBookmarkDataSource
    let pageDS: PageBookmarkDataSource
    let ayahDS: AyahBookmarkDataSource

    init(
         simplePersistence: SimplePersistence,
         lastPagesPersistence: LastPagesPersistence,
         bookmarksPersistence: BookmarksPersistence,
         ayahPersistence: AyahTextPersistence) {

        // configure the data sources
        lastPageDS = LastPageBookmarkDataSource(persistence: lastPagesPersistence)
        pageDS = PageBookmarkDataSource(persistence: bookmarksPersistence)
        ayahDS = AyahBookmarkDataSource(persistence: bookmarksPersistence, ayahPersistence: ayahPersistence)

        dataSource.addDataSource(lastPageDS, headerTitle: lAndroid("recent_pages"))
        dataSource.addDataSource(pageDS, headerTitle: lAndroid("menu_bookmarks_page"))
        dataSource.addDataSource(ayahDS, headerTitle: lAndroid("menu_bookmarks_ayah"))

        super.init(nibName: nil, bundle: nil)

        let lastPageSelection = BlockSelectionHandler<LastPage, BookmarkTableViewCell>()
        lastPageSelection.didSelectBlock = { [weak self] (ds, _, index) in
            let item = ds.item(at:index)
            self?.navigateToPage(item.page, lastPage: item)
        }
        lastPageDS.setSelectionHandler(lastPageSelection)

        let pageSelection = BlockSelectionHandler<PageBookmark, BookmarkTableViewCell>()
        pageSelection.didSelectBlock = { [weak self] (ds, _, index) in
            let item = ds.item(at:index)
            self?.navigateToPage(item.page, lastPage: nil)
        }
        pageDS.setSelectionHandler(pageSelection)

        let ayahSelection = BlockSelectionHandler<AyahBookmark, AyahBookmarkTableViewCell>()
        ayahSelection.didSelectBlock = { [weak self] (ds, _, index) in
            let item = ds.item(at:index)
            self?.navigateToPage(item.page, lastPage: nil)
        }
        ayahDS.setSelectionHandler(ayahSelection)
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = lAndroid("menu_bookmarks")

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70

        tableView.ds_register(headerFooterClass: JuzTableViewHeaderFooterView.self)
        tableView.ds_register(cellNib: BookmarkTableViewCell.self)
        tableView.ds_register(cellNib: AyahBookmarkTableViewCell.self)
        tableView.ds_useDataSource(dataSource)

        editController.configure(tableView: tableView, delegate: self, navigationItem: navigationItem)

        pageDS.delegate = self
        ayahDS.delegate = self

        pageDS.onItemsUpdated = { [weak self] _ in
            self?.editController.onEditableItemsUpdated()
        }
        ayahDS.onItemsUpdated = { [weak self] _ in
            self?.editController.onEditableItemsUpdated()
        }

        pageDS.onEditingChanged = { [weak self] in
            self?.editController.onStartSwipingToEdit()
        }
        ayahDS.onEditingChanged = { [weak self] in
            self?.editController.onStartSwipingToEdit()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        lastPageDS.reloadData()
        pageDS.reloadData()
        ayahDS.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        editController.endEditing(animated)
    }

    fileprivate func navigateToPage(_ page: Int, lastPage: LastPage?) {
        listener?.navigateTo(quranPage: page, lastPage: lastPage)
    }

    func hasItemsToEdit() -> Bool {
        return !pageDS.items.isEmpty || !ayahDS.items.isEmpty
    }

    func bookmarkDataSource(_ dataSource: AbstractDataSource, errorOccurred error: Error) {
        showErrorAlert(error: error)
    }
}
