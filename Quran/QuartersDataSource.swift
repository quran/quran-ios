//
//  QuartersDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class QuartersDataSource: BaseJuzsHeaderDataSource<Quarter, QuarterTableViewCell> {

    let dataRetriever: QuartersDataRetriever

    init(reuseIdentifier: String, juz: Juz, dataRetriever: QuartersDataRetriever) {
        self.dataRetriever = dataRetriever
        super.init(reuseIdentifier: reuseIdentifier, juz: juz)
    }
}
