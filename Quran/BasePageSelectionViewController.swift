//
//  BasePageSelectionViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/30/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import GenericDataSources

class BasePageSelectionViewController<ItemType: QuranPageReference, CellType: ReusableCell>: BaseTableViewController {

    let dataRetriever: AnyDataRetriever<[(Juz, [ItemType])]>
    let quranControllerCreator: AnyCreator<QuranViewController>

    let dataSource = JuzsMutlipleSectionDataSource(type: .MultiSection, headerReuseIdentifier: "header")

    init(dataRetriever: AnyDataRetriever<[(Juz, [ItemType])]>, quranControllerCreator: AnyCreator<QuranViewController>) {
        self.dataRetriever = dataRetriever
        self.quranControllerCreator = quranControllerCreator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = ""
        navigationItem.titleView = UIImageView(image: UIImage(named: "logo-22")?.imageWithRenderingMode(.AlwaysTemplate))

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70

        tableView.registerClass(JuzTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")

        tableView.ds_useDataSource(dataSource)

        dataRetriever.retrieve { [weak self] (data: [(Juz, [ItemType])]) in

            guard let `self` = self else {
                return
            }

            self.dataSource.setSections(data) { self.wrappedCreateItemsDataSource() }
            self.tableView.reloadData()
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.hidesBarsOnSwipe = true
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnSwipe = false
    }

    private func wrappedCreateItemsDataSource() -> BasicDataSource<ItemType, CellType> {
        let selectionHandler = BlockSelectionHandler<ItemType, CellType>()
        selectionHandler.didSelectBlock = { [weak self] (ds, _, index) in
            let item = ds.itemAtIndexPath(index)
            self?.navigateToPage(item.startPageNumber)
        }

        let dataSource = createItemsDataSource()
        dataSource.setSelectionHandler(selectionHandler)
        return dataSource
    }

    func createItemsDataSource() -> BasicDataSource<ItemType, CellType> {
        fatalError("Should be implemented by subclasses")
    }

    private func navigateToPage(page: Int) {
        let controller = self.quranControllerCreator.create()
        controller.initialPage = page
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }
}
