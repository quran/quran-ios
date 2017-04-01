//
//  BaseBasicDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/25/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import GenericDataSources

class BaseBasicDataSource<ItemType, CellType: ReusableCell>: BasicDataSource<ItemType, CellType> {

    init() {
        super.init(reuseIdentifier: CellType.reuseId)
    }
}
