//
//  BasePageSelectionViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/30/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import GenericDataSources

class BasePageSelectionViewController<ItemType, CellType: ReusableCell>: UIViewController {

    let dataRetriever: AnyDataRetriever<[(Juz, [ItemType])]>
    let dataSource = JuzsMutlipleSectionDataSource(type: .MultiSection, headerReuseIdentifier: "header")

    init(dataRetriever: AnyDataRetriever<[(Juz, [ItemType])]>) {
        self.dataRetriever = dataRetriever
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    let tableView = UITableView()
    let statusView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()

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

            self.dataSource.setSections(data) { self.createItemsDataSource() }
            self.tableView.reloadData()
        }
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition({ [weak self] (_) in
            self?.statusView.alpha = size.width > size.height ? 0 : 1
            }, completion: nil)
    }

    private func setUpViews() {
        view.addAutoLayoutSubview(tableView)
        view.pinParentAllDirections(tableView)


        statusView.backgroundColor = UIColor.appIdentity()
        view.addAutoLayoutSubview(statusView)
        view.pinParentHorizontal(statusView)
        view.addParentTopConstraint(statusView)
        statusView.addHeightConstraint(20)
    }

    func createItemsDataSource() -> BasicDataSource<ItemType, CellType> {
        fatalError("Should be implemented by subclasses")
    }
}
