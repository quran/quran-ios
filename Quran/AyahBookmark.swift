//
//  AyahBookmark.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct AyahBookmark: Bookmark {

    let ayah: AyahNumber
    let page: Int
    let creationDate: Date
    var tags: [Tag]
}
