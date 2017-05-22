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

class BookmarksTableViewController: BaseTableBasedViewController, EditControllerDelegate, BookmarkDataSourceDelegate {

    override var screen: Analytics.Screen { return .bookmarks }

    let editController = EditController(usesRightBarButton: true)
    let dataSource: BookmarksDataSource = BookmarksDataSource(type: .multi)
    let lastPageDS: LastPageBookmarkDataSource
    let pageDS: PageBookmarkDataSource
    let ayahDS: AyahBookmarkDataSource

    let quranControllerCreator: AnyCreator<(Int, LastPage?, AyahNumber?), QuranViewController>

    init(
         quranControllerCreator: AnyCreator<(Int, LastPage?, AyahNumber?), QuranViewController>,
         simplePersistence: SimplePersistence,
         lastPagesPersistence: LastPagesPersistence,
         bookmarksPersistence: BookmarksPersistence,
         ayahPersistence: AyahTextPersistence) {
        self.quranControllerCreator = quranControllerCreator

        // configure the data sources
        lastPageDS = LastPageBookmarkDataSource(persistence: lastPagesPersistence)
        pageDS = PageBookmarkDataSource(persistence: bookmarksPersistence)
        ayahDS = AyahBookmarkDataSource(persistence: bookmarksPersistence, ayahPersistence: ayahPersistence)

        dataSource.addDataSource(lastPageDS, headerTitle: NSLocalizedString("menu_jump_last_page", tableName: "Android", comment: ""))
        dataSource.addDataSource(pageDS, headerTitle: NSLocalizedString("menu_bookmarks_page", tableName: "Android", comment: ""))
        dataSource.addDataSource(ayahDS, headerTitle: NSLocalizedString("menu_bookmarks_ayah", tableName: "Android", comment: ""))

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

        let ayahSelection = BlockSelectionHandler<AyahBookmark, BookmarkTableViewCell>()
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
        title = NSLocalizedString("menu_bookmarks", tableName: "Android", comment: "")

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70

        tableView.ds_register(headerFooterClass: JuzTableViewHeaderFooterView.self)
        tableView.ds_register(cellNib: BookmarkTableViewCell.self)
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
        Analytics.shared.openingQuran(from: screen)
        let controller = self.quranControllerCreator.create((page, lastPage, nil))
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }

    func hasItemsToEdit() -> Bool {
        return !pageDS.items.isEmpty || !ayahDS.items.isEmpty
    }

    func bookmarkDataSource(_ dataSource: AbstractDataSource, errorOccurred error: Error) {
        showErrorAlert(error: error)
    }
}
