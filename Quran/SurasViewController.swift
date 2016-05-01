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

    override init(dataRetriever: AnyDataRetriever<[(Juz, [Sura])]>, quranControllerCreator: AnyCreator<QuranViewController>) {
        super.init(dataRetriever: dataRetriever, quranControllerCreator: quranControllerCreator)
    }

    override func createItemsDataSource() -> BasicDataSource<Sura, SuraTableViewCell> {
        return SurasDataSource(reuseIdentifier: "cell")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: "SuraTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
}
