//
//  BookmarksDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class BookmarksDataSource: CompositeDataSource {

    private let headerCreator: BasicBlockSupplementaryViewCreator<String, JuzTableViewHeaderFooterView>

    init(type: SectionType, headerReuseIdentifier: String) {
        headerCreator = BasicBlockSupplementaryViewCreator(
        identifier: headerReuseIdentifier, size: CGSize(width: 0, height: 44)) { (item, view, _) in
            view.titleLabel.text =  item
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
