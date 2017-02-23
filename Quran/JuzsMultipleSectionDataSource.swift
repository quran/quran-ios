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

    let numberFormatter = NumberFormatter()

    let headerReuseIdentifier: String

    var juzs: [Juz] = []

    var onJuzHeaderSelected: ((Juz) -> Void)?

    init(type: SectionType, headerReuseIdentifier: String) {
        self.headerReuseIdentifier = headerReuseIdentifier
        super.init(sectionType: type)
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
        juzs = sections.map { $0.0 }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header: JuzTableViewHeaderFooterView = cast(tableView.dequeueReusableHeaderFooterView(withIdentifier: headerReuseIdentifier))
        let juz = juzs[section]

        header.titleLabel.text = String(format: NSLocalizedString("juz2_description", tableName: "Android", comment: ""), juz.juzNumber)
        header.subtitleLabel.text = numberFormatter.string(from: NSNumber(value: juz.startPageNumber))

        header.object = juz
        header.onTapped = { [weak self] in
            guard let object = header.object as? Juz else { return }

            self?.onJuzHeaderSelected?(object)
        }
        return header
    }
}
