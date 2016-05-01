//
//  JuzsViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import GenericDataSources

class JuzsViewController: BasePageSelectionViewController<Quarter, QuarterTableViewCell> {

    override init(dataRetriever: AnyDataRetriever<[(Juz, [Quarter])]>) {
        super.init(dataRetriever: dataRetriever)
    }

    override func createItemsDataSource() -> BasicDataSource<Quarter, QuarterTableViewCell> {
        return QuartersDataSource(reuseIdentifier: "cell")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: "QuarterTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
}
