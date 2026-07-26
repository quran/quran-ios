//
//  QuarterItem.swift
//
//
//  Created by Mohamed Afifi on 2023-07-16.
//

import QuranKit
import QuranText

struct QuarterItem: Identifiable {
    let quarter: Quarter
    let ayahText: QuranText

    var id: Quarter { quarter }
}
