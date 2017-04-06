//
//  JuzsMultipleSectionDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class JuzsMultipleSectionDataSource: CompositeDataSource {

    var onJuzHeaderSelected: ((Juz) -> Void)? {
        set { headerCreator.onJuzHeaderSelected = newValue }
        get { return headerCreator.onJuzHeaderSelected }
    }

    private let headerCreator: JuzHeaderSupplementaryViewCreator

    override init(sectionType: SectionType) {
        headerCreator = JuzHeaderSupplementaryViewCreator()
        super.init(sectionType: sectionType)
        set(headerCreator: headerCreator)
    }

    func setSections<ItemType, CellType: ReusableCell>(_ sections: [(Juz, [ItemType])],
                                                       dataSourceCreator: () -> BasicDataSource<ItemType, CellType>) {

        for dataSource in dataSources {
            remove(dataSource)
        }

        for section in sections {
            let ds = dataSourceCreator()
            ds.items = section.1
            add(ds)
        }
        headerCreator.setSectionedItems(sections.map { $0.0 })
    }
}
