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
        unimplemented()
    }

    override func createItemsDataSource() -> BasicDataSource<Quarter, QuarterTableViewCell> {
        return QuartersDataSource()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.ds_register(cellNib: QuarterTableViewCell.self)
    }
}
