//
//  FileSystemError.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

enum FileSystemError: ErrorType, CustomStringConvertible {

    case NoDiskSpace
    case Unknown

    init(error: ErrorType) {
        if let error = error as? NSCocoaError {
            if error == .FileWriteOutOfSpaceError {
                self = .NoDiskSpace
            } else {
                self = .Unknown
            }
        } else {
            self = .Unknown
        }
    }

    var description: String {
        let text: String
        switch self {
        case .Unknown:
            text = NSLocalizedString("FileSystemError_Unknown", comment: "")
        case .NoDiskSpace:
            text = NSLocalizedString("FileSystemError_NoDiskSpace", comment: "")
        }
        return text
    }
}
