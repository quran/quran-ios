//
//  QuartersDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class QuartersDataSource: BasicDataSource<Quarter, QuarterTableViewCell> {

    // this is needed as of swift 2.2 as class don't inherit constructors from generic based.
    override init(reuseIdentifier: String) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
}
