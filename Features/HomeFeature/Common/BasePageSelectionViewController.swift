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

import AnnotationsService
import FeaturesSupport
import Localization
import NoorUI
import QuranKit
import UIKit
import UIx
import Utilities

class BasePageSelectionViewController: BaseTableBasedViewController {
    // MARK: Lifecycle

    init(navigator: QuranNavigator, lastPageService: LastPageService) {
        self.navigator = navigator
        lastPageDS = LastPageBookmarkDataSource(service: lastPageService)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: Internal

    let navigator: QuranNavigator

    lazy var dataSource: JuzsMultipleSectionDataSource = {
        let ds = JuzsMultipleSectionDataSource(sectionType: .multi)
        ds.headerCreator.controller = self
        ds.headerCreator.setSectionedItems([lAndroid("recent_pages")])
        return ds
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedSectionHeaderHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70

        tableView.ds_register(cellClass: HostingTableViewCell<LastPageCell>.self)
        tableView.ds_register(headerFooterClass: HostingTableViewHeaderFooterView<TableHeaderView>.self)
        tableView.ds_useDataSource(dataSource)

        addLastPageDataSource()
    }

    func setJuzs(_ juzs: [Juz]) {
        let lastPageHeader = lAndroid("recent_pages")
        let localizedJuzs = juzs.map(\.localizedName)
        dataSource.headerCreator.setSectionedItems([lastPageHeader] + localizedJuzs)
    }

    // MARK: Private

    private let lastPageDS: LastPageBookmarkDataSource

    private func addLastPageDataSource() {
        lastPageDS.controller = self
        dataSource.insert(lastPageDS, at: 0)
        lastPageDS.setDidSelect { [weak self] ds, _, index in
            let item = ds.item(at: index)
            self?.navigator.navigateTo(page: item.page, lastPage: item, highlightingSearchAyah: nil)
        }
    }
}
