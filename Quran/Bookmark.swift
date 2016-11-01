//
//  Bookmark.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol Bookmark {
    var page: Int { get }
    var creationDate: Date { get }
    var tags: [Tag] { get }
}
