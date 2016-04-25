//
//  Truth.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

typealias Rect = CGRect
typealias Size = CGSize

struct Truth {
    static var Host: NSURL = {
        guard let url = NSURL(string: "http://android.quran.com/") else {
            fatalError("Invalid Host URL")
        }
        return url
    }()

    static let QuranPagesRange: Range<Int> = 1..<604
    static var QuranSurasRange: Range<Int> = 1..<114
    static var QuranJuzsRange: Range<Int>  = 1..<30

}
