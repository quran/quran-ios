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
import Localization

public enum FileSystemError: Error {
    case noDiskSpace
    case unknown(Error)

    // MARK: Lifecycle

    public init(error: Error) {
        if let error = error as? CocoaError {
            if error.code == .fileWriteOutOfSpace {
                self = .noDiskSpace
            } else {
                self = .unknown(error)
            }
        } else {
            self = .unknown(error)
        }
    }
}

extension FileSystemError: LocalizedError {
    public var errorDescription: String? {
        let text: String = switch self {
        case .unknown:
            l("error.message.general")
        case .noDiskSpace:
            l("error.message.no_disk_space")
        }
        return text
    }
}
