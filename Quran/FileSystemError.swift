//
//  FileSystemError.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
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

enum FileSystemError: QuranError {

    case noDiskSpace
    case unknown

    init(error: Error) {
        if let error = error as? CocoaError {
            if error.code == .fileWriteOutOfSpace {
                self = .noDiskSpace
            } else {
                self = .unknown
            }
        } else {
            self = .unknown
        }
    }

    var localizedDescriptionv2: String {
        let text: String
        switch self {
        case .unknown:
            text = NSLocalizedString("FileSystemError_Unknown", comment: "")
        case .noDiskSpace:
            text = NSLocalizedString("FileSystemError_NoDiskSpace", comment: "")
        }
        return text
    }
}
