//
//  TranslationPageLayoutRequest.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/1/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import CoreGraphics

struct TranslationPageLayoutRequest: Hashable {
    let page: TranslationPage
    let width: CGFloat

    var hashValue: Int {
        return page.hashValue ^ width.hashValue
    }

    static func == (lhs: TranslationPageLayoutRequest, rhs: TranslationPageLayoutRequest) -> Bool {
        return lhs.page == rhs.page && lhs.width == rhs.width
    }
}
