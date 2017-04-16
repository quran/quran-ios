//
//  QuranDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/19/17.
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

import Foundation
import GenericDataSources

class QuranDataSource: SegmentedDataSource {

    private let dataSourceHandlers: [QuranDataSourceHandler]
    private let dataSourceRepresentables: [AnyBasicDataSourceRepresentable<QuranPage>]

    var onScrollViewWillBeginDragging: (() -> Void)?

    private var selectedDataSourceHandler: QuranDataSourceHandler {
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

    init(dataSources: [AnyBasicDataSourceRepresentable<QuranPage>], handlers: [QuranDataSourceHandler]) {
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
        handlers.forEach {
            $0.onScrollViewWillBeginDragging = { [weak self] in
                self?.onScrollViewWillBeginDragging?()
            }
        }
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
