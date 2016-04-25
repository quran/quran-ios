//
//  BaseJuzsHeaderDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

// implement here only the header view
class BaseJuzsHeaderDataSource<ItemType, CellType: ReusableCell>: BasicDataSource<ItemType, CellType> {

    // juz will be used as header view
    let juz: Juz

    init(reuseIdentifier: String, juz: Juz) {
        self.juz = juz
        super.init(reuseIdentifier: reuseIdentifier)
    }
}
