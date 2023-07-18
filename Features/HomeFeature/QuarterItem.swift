//
//  QuarterItem.swift
//
//
//  Created by Mohamed Afifi on 2023-07-16.
//

import QuranKit

struct QuarterItem: Identifiable {
    let quarter: Quarter
    let ayahText: String

    var id: Quarter { quarter }
}
