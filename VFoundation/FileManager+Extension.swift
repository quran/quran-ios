//
//  FileManager+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation

extension FileManager {

    public static let documentsPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

    public static let documentsURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    public static var tempFileURL: URL {
        let fileName = NSUUID().uuidString
        let temp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        return temp
    }
}
