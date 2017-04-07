//
//  SurasViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import GenericDataSources

class SurasViewController: BasePageSelectionViewController<Sura, SuraTableViewCell> {

    override init(dataRetriever: AnyDataRetriever<[(Juz, [Sura])]>, quranControllerCreator: AnyCreator<QuranViewController, (Int, LastPage?)>) {
        super.init(dataRetriever: dataRetriever, quranControllerCreator: quranControllerCreator)
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    override func createItemsDataSource() -> BasicDataSource<Sura, SuraTableViewCell> {
        return SurasDataSource()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.ds_register(cellNib: SuraTableViewCell.self)
    }
}
