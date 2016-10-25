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

    var headerTitles: [String] = []
    let headerReuseIdentifier: String

    init(type: SectionType, headerReuseIdentifier: String) {
        self.headerReuseIdentifier = headerReuseIdentifier
        super.init(sectionType: type)
    }

    func addDataSource(_ dataSource: DataSource, headerTitle: String) {
        headerTitles.append(headerTitle)
        super.addDataSource(dataSource)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header: JuzTableViewHeaderFooterView = cast(tableView.dequeueReusableHeaderFooterView(withIdentifier: headerReuseIdentifier))
        let text = headerTitles[section]
        header.titleLabel.text =  text
        header.subtitleLabel.isHidden = true
        return header
    }
}
