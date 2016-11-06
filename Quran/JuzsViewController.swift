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

    override init(dataRetriever: AnyDataRetriever<[(Juz, [Quarter])]>, quranControllerCreator: AnyCreator<QuranViewController, (Int, LastPage?)>) {
        super.init(dataRetriever: dataRetriever, quranControllerCreator: quranControllerCreator)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func createItemsDataSource() -> BasicDataSource<Quarter, QuarterTableViewCell> {
        return QuartersDataSource(reuseIdentifier: "cell")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "QuarterTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
}
