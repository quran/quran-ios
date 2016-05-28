//
//  BookmarksTableViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import GenericDataSources

class BookmarksTableViewController: UITableViewController {

    let dataSource: BookmarksDataSource = BookmarksDataSource(type: .MultiSection, headerReuseIdentifier: "header")
    let lastPageDS: LastPageBookmarkDataSource
    let quranControllerCreator: AnyCreator<QuranViewController>

    init(persistence: SimplePersistence, quranControllerCreator: AnyCreator<QuranViewController>) {
        self.quranControllerCreator = quranControllerCreator
        lastPageDS = LastPageBookmarkDataSource(reuseIdentifier: "cell", persistence: persistence)
        dataSource.addDataSource(lastPageDS, headerTitle: NSLocalizedString("menu_jump_last_page", tableName: "Android", comment: ""))

        super.init(style: .Plain)

        let selectionHandler = BlockSelectionHandler<Int, BookmarkTableViewCell>()
        selectionHandler.didSelectBlock = { [weak self] (ds, _, index) in
            let item = ds.itemAtIndexPath(index)
            self?.navigateToPage(item)
        }
        lastPageDS.setSelectionHandler(selectionHandler)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = ""
        navigationItem.titleView = UIImageView(image: UIImage(named: "logo-22")?.imageWithRenderingMode(.AlwaysTemplate))

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70

        tableView.registerClass(JuzTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")
        tableView.registerNib(UINib(nibName: "BookmarkTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.ds_useDataSource(dataSource)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        lastPageDS.reloadData()
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: animated)
        }
    }

    private func navigateToPage(page: Int) {
        let controller = self.quranControllerCreator.create()
        controller.initialPage = page
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }
}
