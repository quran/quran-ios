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

    init(type: Type, headerReuseIdentifier: String) {
        self.headerReuseIdentifier = headerReuseIdentifier
        super.init(type: type)
    }

    func addDataSource(dataSource: DataSource, headerTitle: String) {
        headerTitles.append(headerTitle)
        super.addDataSource(dataSource)
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header: JuzTableViewHeaderFooterView = cast(tableView.dequeueReusableHeaderFooterViewWithIdentifier(headerReuseIdentifier))
        let text = headerTitles[section]
        header.titleLabel.text =  text
        header.subtitleLabel.hidden = true
        return header
    }
}
