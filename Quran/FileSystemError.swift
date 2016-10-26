//
//  FileSystemError.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

enum FileSystemError: Error, CustomStringConvertible {

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

    var description: String {
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
