//
//  SurasViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import GenericDataSources

class SurasViewController: UIViewController {

    let dataRetriever: AnyDataRetriever<[(Juz, [Sura])]>
    let dataSource = JuzsMutlipleSectionDataSource(type: .MultiSection, headerReuseIdentifier: "header")

    init(dataRetriever: AnyDataRetriever<[(Juz, [Sura])]>) {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()

        title = NSBundle.mainBundle().localizedInfoDictionary?["CFBundleName"] as? String ?? ""
        view.backgroundColor = UIColor.secondaryColor()
        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70

        tableView.registerNib(UINib(nibName: "SuraTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.registerClass(JuzTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")

        tableView.ds_useDataSource(dataSource)

        dataRetriever.retrieve { [weak self] data in
            self?.dataSource.setSections(data) { SurasDataSource(reuseIdentifier: "cell") }
        }
    }

    private func setUpViews() {
        view.addAutoLayoutSubview(tableView)
        view.pinParentAllDirections(tableView)

        let statusView = UIView()
        statusView.backgroundColor = UIColor.appIdentity()
        view.addAutoLayoutSubview(statusView)
        view.pinParentHorizontal(statusView)
        view.addParentTopConstraint(statusView)
        statusView.addHeightConstraint(20)
    }
}
