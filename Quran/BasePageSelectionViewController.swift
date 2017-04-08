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

import UIKit
import GenericDataSources

class BasePageSelectionViewController<ItemType: QuranPageReference, CellType: ReusableCell>: BaseTableBasedViewController {

    let dataRetriever: AnyDataRetriever<[(Juz, [ItemType])]>
    let quranControllerCreator: AnyCreator<QuranViewController, (Int, LastPage?)>

    let dataSource = JuzsMultipleSectionDataSource(sectionType: .multi)

    init(dataRetriever: AnyDataRetriever<[(Juz, [ItemType])]>, quranControllerCreator: AnyCreator<QuranViewController, (Int, LastPage?)>) {
        self.dataRetriever = dataRetriever
        self.quranControllerCreator = quranControllerCreator
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
        navigationItem.title = ""
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "logo22").withRenderingMode(.alwaysTemplate))

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70

        tableView.ds_register(headerFooterClass: JuzTableViewHeaderFooterView.self)
        tableView.ds_useDataSource(dataSource)

        dataRetriever.retrieve { [weak self] (data: [(Juz, [ItemType])]) in

            guard let `self` = self else {
                return
            }

            self.dataSource.setSections(data) { self.wrappedCreateItemsDataSource() }
            self.tableView.reloadData()
        }

        dataSource.onJuzHeaderSelected = { [weak self] juz in
            self?.navigateToPage(juz.startPageNumber)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.hidesBarsOnSwipe = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnSwipe = false
    }

    fileprivate func wrappedCreateItemsDataSource() -> BasicDataSource<ItemType, CellType> {
        let selectionHandler = BlockSelectionHandler<ItemType, CellType>()
        selectionHandler.didSelectBlock = { [weak self] (ds, _, index) in
            let item = ds.item(at: index)
            self?.navigateToPage(item.startPageNumber)
        }

        let dataSource = createItemsDataSource()
        dataSource.setSelectionHandler(selectionHandler)
        return dataSource
    }

    func createItemsDataSource() -> BasicDataSource<ItemType, CellType> {
        fatalError("Should be implemented by subclasses")
    }

    fileprivate func navigateToPage(_ page: Int) {
        let controller = self.quranControllerCreator.create((page, nil))
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }
}
