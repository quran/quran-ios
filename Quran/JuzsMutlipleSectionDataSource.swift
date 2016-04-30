//
//  JuzsMutlipleSectionDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources


class JuzsMutlipleSectionDataSource: CompositeDataSource {

    let headerReuseIdentifier: String

    var juzs: [Juz] = []

    init(type: Type, headerReuseIdentifier: String) {
        self.headerReuseIdentifier = headerReuseIdentifier
        super.init(type: type)
    }

    func setSections<ItemType, CellType: ReusableCell>(sections: [(Juz, [ItemType])],
                     @noescape dataSourceCreator: () -> BasicDataSource<ItemType, CellType>) {

        for dataSource in dataSources {
            removeDataSource(dataSource)
        }

        for section in sections {
            let ds = dataSourceCreator()
            ds.items = section.1
            addDataSource(ds)
        }
        juzs = sections.map { $0.0 }
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header: JuzTableViewHeaderFooterView = cast(tableView.dequeueReusableHeaderFooterViewWithIdentifier(headerReuseIdentifier))
        let juz = juzs[section]

        header.label.text = String(format: NSLocalizedString("juz2_description", comment: ""), juz.order)
        return header
    }
}
