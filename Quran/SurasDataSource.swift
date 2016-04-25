//
//  SurasDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class SurasDataSource: BaseJuzsHeaderDataSource<Sura, SuraTableViewCell> {

    let dataRetriever: SurasDataRetriever

    init(reuseIdentifier: String, juz: Juz, dataRetriever: SurasDataRetriever) {
        self.dataRetriever = dataRetriever
        super.init(reuseIdentifier: reuseIdentifier, juz: juz)
    }
}
