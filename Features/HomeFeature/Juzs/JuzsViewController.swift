//
//  JuzsViewController.swift
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

class JuzsViewController: BasePageSelectionViewController, JuzsPresentable {
    // MARK: Lifecycle

    init(interactor: JuzsInteractor, lastPageService: LastPageService) {
        self.interactor = interactor
        super.init(navigator: interactor, lastPageService: lastPageService)
        interactor.presenter = self
        interactor.start()
    }

    // MARK: Internal

    let interactor: JuzsInteractor

    override func viewDidLoad() {
        super.viewDidLoad()
        title = lAndroid("quran_juz2")
        tableView.ds_register(cellClass: HostingTableViewCell<HomeQuarterCell>.self)
    }

    func setQuarters(_ quartersDictionary: [Juz: [Quarter]], juzs: [Juz], quartersText: [Quarter: String]) {
        setJuzs(juzs)

        for ds in dataSource.dataSources where ds is QuartersDataSource {
            dataSource.remove(ds)
        }

        for juz in juzs {
            let quartersDataSource = QuartersDataSource()
            quartersDataSource.controller = self
            quartersDataSource.setDidSelect { [weak self] ds, _, index in
                let item = ds.item(at: index)
                self?.interactor.navigateTo(page: item.quarter.page, lastPage: nil, highlightingSearchAyah: nil)
            }
            let quarters = quartersDictionary[juz] ?? []
            quartersDataSource.items = quarters.map { quarter in
                (quarter: quarter, text: quartersText[quarter]!)
            }
            dataSource.add(quartersDataSource)
        }

        tableView?.reloadData()
    }
}
