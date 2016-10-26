//
//  URL.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct QuranURLs {

    static var Host: URL = URL(validURL: "http://android.quran.com/")

    static var AudioDatabaseURL: URL = Host.appendingPathComponent("data/databases/audio/")
}
