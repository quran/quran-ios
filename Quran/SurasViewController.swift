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
        fatalError("init(coder:) has not been implemented")
    }

    override func createItemsDataSource() -> BasicDataSource<Sura, SuraTableViewCell> {
        return SurasDataSource(reuseIdentifier: "cell")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "SuraTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
}
