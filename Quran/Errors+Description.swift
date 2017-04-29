//
//  Errors+Description.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/28/17.
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

import SQLitePersistence
import BatchDownloader

extension FileSystemError: LocalizedError {

    public var errorDescription: String {
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

extension NetworkError: LocalizedError {

    public var errorDescription: String {
        let text: String
        switch self {
        case .unknown:
            text = NSLocalizedString("NetworkError_Unknown", comment: "Error description")
        case .serverError:
            text = NSLocalizedString("NetworkError_Unknown", comment: "Error description")
        case .notConnectedToInternet:
            text = NSLocalizedString("NetworkError_NotConnectedToInternet", comment: "Error description")
        case .internationalRoamingOff:
            text = NSLocalizedString("NetworkError_InternationalRoamingOff", comment: "Error description")
        case .serverNotReachable:
            text = NSLocalizedString("NetworkError_ServerNotReachable", comment: "Error description")
        case .connectionLost:
            text = NSLocalizedString("NetworkError_ConnectionLost", comment: "Error description")
        }
        return text
    }
}

extension ParsingError: LocalizedError {
    public var errorDescription: String {
        return NSLocalizedString("NetworkError_Parsing", comment: "When a parsing error occurs")
    }
}

extension PersistenceError: LocalizedError {
    public var errorDescription: String {
        return NSLocalizedString("NetworkError_Unknown", comment: "")
    }
}
