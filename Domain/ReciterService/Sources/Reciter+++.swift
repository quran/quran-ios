//
//  Reciter+++.swift
//
//
//  Created by Mohamed Afifi on 2023-06-04.
//

import Localization
import Reciter

extension Reciter {
    public var localizedName: String {
        l(nameKey, table: .readers)
    }
}
