//
//  BookmarksDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/16.
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

class BookmarksDataSource: CompositeDataSource {

    private let headerCreator: BasicBlockSupplementaryViewCreator<String, JuzTableViewHeaderFooterView>

    init(type: SectionType) {
        headerCreator = BasicBlockSupplementaryViewCreator(size: CGSize(width: 0, height: 44)) { (item, view, _) in
            view.titleLabel.text = item
            view.subtitleLabel.isHidden = true
        }
        super.init(sectionType: type)
        set(headerCreator: headerCreator)
    }

    func addDataSource(_ dataSource: DataSource, headerTitle: String) {
        headerCreator.items.append([headerTitle])
        super.add(dataSource)
    }
}
