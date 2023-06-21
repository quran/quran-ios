//
//  SurasViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
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

import AnnotationsService
import Localization
import NoorUI
import QuranKit
import UIKit
import UIx

class SurasViewController: BasePageSelectionViewController, SurasPresentable {
    // MARK: Lifecycle

    init(interactor: SurasInteractor, lastPageService: LastPageService) {
        self.interactor = interactor
        super.init(navigator: interactor, lastPageService: lastPageService)
        interactor.presenter = self
        interactor.start()
    }

    // MARK: Internal

    let interactor: SurasInteractor

    override func viewDidLoad() {
        super.viewDidLoad()
        title = lAndroid("quran_sura")
        tableView.ds_register(cellClass: HostingTableViewCell<HomeSuraCell>.self)
    }

    func setSuras(_ surasDictionary: [Juz: [Sura]], juzs: [Juz]) {
        setJuzs(juzs)

        for ds in dataSource.dataSources where ds is SurasDataSource {
            dataSource.remove(ds)
        }

        for juz in juzs {
            let surasDataSource = SurasDataSource()
            surasDataSource.controller = self
            surasDataSource.setDidSelect { [weak self] ds, _, index in
                let item = ds.item(at: index)
                self?.navigator.navigateTo(page: item.page, lastPage: nil, highlightingSearchAyah: nil)
            }
            surasDataSource.items = surasDictionary[juz] ?? []
            dataSource.add(surasDataSource)
        }

        tableView?.reloadData()
    }
}
