//
//  URL.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct URL {

    static var Host: NSURL = {
        guard let url = NSURL(string: "http://android.quran.com/") else {
            fatalError("Invalid Host URL")
        }
        return url
    }()

    static var AudioDatabaseURL: NSURL = Host.URLByAppendingPathComponent("data/databases/audio/")
}
