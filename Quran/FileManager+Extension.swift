//
//  FileManager+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

extension FileManager {

    var documentsPath: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }

    var documentsURL: URL {
        return urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var tempFileURL: URL {
        let fileName = NSUUID().uuidString
        let temp = URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        return temp
    }
}
