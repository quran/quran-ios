//
//  Files.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/30/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct Files {
    static let QuarterPrefixArray: NSURL = fileURL("quarter_prefix_array", withExtension: "plist")
}

func fileURL(fileName: String, withExtension: String) -> NSURL {
    guard let url = NSBundle.mainBundle().URLForResource(fileName, withExtension: withExtension) else {
        fatalError("Couldn't find file `\(fileName).\(withExtension)` locally ")
    }
    return url
}
