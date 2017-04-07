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

    private let dataSourceHandlers: [AnyQuranDataSourceHandler<QuranPage>]
    private let dataSourceRepresentables: [AnyBasicDataSourceRepresentable<QuranPage>]

    private var selectedDataSourceHandler: AnyQuranDataSourceHandler<QuranPage> {
        return dataSourceHandlers[selectedDataSourceIndex]
    }

    var selectedBasicDataSource: AnyBasicDataSourceRepresentable<QuranPage> {
        return dataSourceRepresentables[selectedDataSourceIndex]
    }

    override var selectedDataSource: DataSource? {
        didSet {
            if oldValue !== selectedDataSource {
                ds_reusableViewDelegate?.ds_reloadData()
            }
        }
    }

    init(dataSources: [AnyBasicDataSourceRepresentable<QuranPage>], handlers: [AnyQuranDataSourceHandler<QuranPage>]) {
        assert(dataSources.count == handlers.count)
        self.dataSourceHandlers = handlers
        self.dataSourceRepresentables = dataSources
        super.init()
        for ds in dataSources {
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
        selectedDataSourceHandler.applicationDidBecomeActive()
    }

    func highlightAyaht(_ ayat: Set<AyahNumber>) {
        for (offset, ds) in dataSourceHandlers.enumerated() {
            ds.highlightAyaht(ayat, isActive: offset == selectedDataSourceIndex)
        }
    }

    func setItems(_ items: [QuranPage]) {
        for ds in dataSourceRepresentables {
            ds.items = items
        }
        ds_reusableViewDelegate?.ds_reloadData()
    }

    func invalidate() {
        dataSourceHandlers.forEach { $0.invalidate() }
        ds_reusableViewDelegate?.ds_reloadData()
    }
}
