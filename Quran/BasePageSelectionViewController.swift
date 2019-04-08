//
//  BasePageSelectionViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/30/16.
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

class BasePageSelectionViewController: BaseTableBasedViewController {

    let dataSource = JuzsMultipleSectionDataSource(sectionType: .multi)
    let lastPageDS: LastPageBookmarkDataSource

    private let numberFormatter = NumberFormatter()

    init(lastPagesPersistence: LastPagesPersistence) {
        self.lastPageDS = LastPageBookmarkDataSource(persistence: lastPagesPersistence)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70

        tableView.ds_register(cellNib: BookmarkTableViewCell.self)
        tableView.ds_register(headerFooterClass: JuzTableViewHeaderFooterView.self)
        tableView.ds_useDataSource(dataSource)

        addLastPageDataSource()

        dataSource.onJuzHeaderSelected = { [weak self] juz in
            self?.navigateTo(quranPage: juz.startPageNumber, lastPage: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lastPageDS.reloadData()
    }

    func setJuzs(_ juzs: [Juz]) {
        let lastPageHeader = lAndroid("recent_pages")
        let localizedJuzs = juzs.map { String(format: lAndroid("juz2_description"), numberFormatter.format($0.juzNumber)) }
        self.dataSource.headerCreator.setSectionedItems([lastPageHeader] + localizedJuzs)
    }

    private func addLastPageDataSource() {
        self.dataSource.insert(lastPageDS, at: 0)
        lastPageDS.setDidSelect { [weak self] (ds, _, index) in
            let item = ds.item(at:index)
            self?.navigateTo(quranPage: item.page, lastPage: item)
        }
    }

    func navigateTo(quranPage: Int, lastPage: LastPage?) {
        expectedToBeSubclassed()
    }
}
