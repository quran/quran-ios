//
//  Once.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct Once {

    private var once: dispatch_once_t = 0

    mutating func once(block: () -> Void) {
        dispatch_once(&once, block)
    }
}
