//
//  BookmarksTableViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import GenericDataSources

class BookmarksTableViewController: BaseTableViewController {

    let dataSource: BookmarksDataSource = BookmarksDataSource(type: .multi, headerReuseIdentifier: "header")
    let lastPageDS: LastPageBookmarkDataSource
    let pageDS: PageBookmarkDataSource
    let ayahDS: AyahBookmarkDataSource

    let quranControllerCreator: AnyCreator<QuranViewController, (Int, LastPage?)>

    init(
         quranControllerCreator: AnyCreator<QuranViewController, (Int, LastPage?)>,
         simplePersistence: SimplePersistence,
         lastPagesPersistence: LastPagesPersistence,
         bookmarksPersistence: BookmarksPersistence,
         ayahPersistence: AyahTextPersistence) {
        self.quranControllerCreator = quranControllerCreator

        // configure the data sources
        lastPageDS = LastPageBookmarkDataSource(reuseIdentifier: "cell", persistence: lastPagesPersistence)
        pageDS = PageBookmarkDataSource(reuseIdentifier: "cell", persistence: bookmarksPersistence)
        ayahDS = AyahBookmarkDataSource(reuseIdentifier: "cell", persistence: bookmarksPersistence, ayahPersistence: ayahPersistence)

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
        navigationItem.title = ""
        navigationItem.titleView = UIImageView(image: UIImage(named: "logo-22")?.withRenderingMode(.alwaysTemplate))

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70

        tableView.register(JuzTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")
        tableView.register(UINib(nibName: "BookmarkTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.ds_useDataSource(dataSource)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        lastPageDS.reloadData()
        pageDS.reloadData()
        ayahDS.reloadData()

        // deselect selected row
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }

    fileprivate func navigateToPage(_ page: Int, lastPage: LastPage?) {
        let controller = self.quranControllerCreator.create(page, lastPage)
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }
}
