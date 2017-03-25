//
//  QuranDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/19/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class QuranDataSource: SegmentedDataSource {

    private let dataSourceRepresentables: [AnyQuranBasicDataSourceRepresentable<QuranPage>]

    var selectedDataSourceRepresentable: AnyQuranBasicDataSourceRepresentable<QuranPage>! {
        return selectedDataSourceIndex.map { return dataSourceRepresentables[$0] }
    }

    override var selectedDataSource: DataSource? {
        didSet {
            if oldValue !== selectedDataSource {
                ds_reusableViewDelegate?.ds_reloadData()
            }
        }
    }

    init(dataSourceRepresentables: [AnyQuranBasicDataSourceRepresentable<QuranPage>]) {
        self.dataSourceRepresentables = dataSourceRepresentables
        super.init()
        for ds in dataSourceRepresentables {
            add(ds.dataSource)
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func applicationDidBecomeActive() {
        selectedDataSourceRepresentable?.applicationDidBecomeActive()
    }

    func highlightAyaht(_ ayat: Set<AyahNumber>) {
        selectedDataSourceRepresentable?.highlightAyaht(ayat)
    }

    func setItems(_ items: [QuranPage]) {
        for ds in dataSourceRepresentables {
            ds.items = items
        }
        ds_reusableViewDelegate?.ds_reloadData()
    }

    func invalidate() {
        dataSourceRepresentables.forEach { $0.invalidate() }
        ds_reusableViewDelegate?.ds_reloadData()
    }
}
