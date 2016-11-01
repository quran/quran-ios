//
//  PageBookmark.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct PageBookmark: Bookmark {

    let page: Int
    let creationDate: Date
    var tags: [Tag]
}
