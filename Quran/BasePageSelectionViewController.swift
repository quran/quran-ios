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

class BasePageSelectionViewController<ItemType: QuranPageReference, CellType: ReusableCell>: BaseTableBasedViewController {

    let dataRetriever: AnyGetInteractor<[(Juz, [ItemType])]>
    let quranControllerCreator: AnyCreator<(Int, LastPage?, AyahNumber?), QuranViewController>

    let dataSource = JuzsMultipleSectionDataSource(sectionType: .multi)
    let lastPageDS: LastPageBookmarkDataSource

    private let numberFormatter = NumberFormatter()

    init(dataRetriever: AnyGetInteractor<[(Juz, [ItemType])]>,
         quranControllerCreator: AnyCreator<(Int, LastPage?, AyahNumber?), QuranViewController>,
         lastPagesPersistence: LastPagesPersistence) {
        self.dataRetriever = dataRetriever
        self.quranControllerCreator = quranControllerCreator
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

        dataRetriever.get().done(on: .main) { [weak self] (data: [(Juz, [ItemType])]) -> Void in
            self?.setSections(data)
            self?.tableView.reloadData()
        }.suppress()

        dataSource.onJuzHeaderSelected = { [weak self] juz in
            self?.navigateToPage(juz.startPageNumber, lastPage: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lastPageDS.reloadData()
    }

    private func setSections(_ sections: [(Juz, [ItemType])]) {
        for ds in dataSource.dataSources {
            self.dataSource.remove(ds)
        }

        addLastPageDataSource()

        for section in sections {
            let ds = wrappedCreateItemsDataSource()
            ds.items = section.1
            dataSource.add(ds)
        }

        let lastPageHeader = lAndroid("recent_pages")
        let juzs = sections.map { String(format: lAndroid("juz2_description"), numberFormatter.format($0.0.juzNumber)) }
        self.dataSource.headerCreator.setSectionedItems([lastPageHeader] + juzs)
    }

    private func addLastPageDataSource() {
        self.dataSource.add(self.lastPageDS)
        let lastPageSelection = BlockSelectionHandler<LastPage, BookmarkTableViewCell>()
        lastPageSelection.didSelectBlock = { [weak self] (ds, _, index) in
            let item = ds.item(at:index)
            self?.navigateToPage(item.page, lastPage: item)
        }
        lastPageDS.setSelectionHandler(lastPageSelection)
    }

    private func wrappedCreateItemsDataSource() -> BasicDataSource<ItemType, CellType> {
        let selectionHandler = BlockSelectionHandler<ItemType, CellType>()
        selectionHandler.didSelectBlock = { [weak self] (ds, _, index) in
            let item = ds.item(at: index)
            self?.navigateToPage(item.startPageNumber, lastPage: nil)
        }

        let dataSource = createItemsDataSource()
        dataSource.setSelectionHandler(selectionHandler)
        return dataSource
    }

    func createItemsDataSource() -> BasicDataSource<ItemType, CellType> {
        fatalError("Should be implemented by subclasses")
    }

    private func navigateToPage(_ page: Int, lastPage: LastPage?) {
        Analytics.shared.openingQuran(from: screen)
        let controller = self.quranControllerCreator.create((page, lastPage, nil))
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }
}
