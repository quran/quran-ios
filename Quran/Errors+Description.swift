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
import BatchDownloader
import SQLitePersistence

extension FileSystemError: LocalizedError {

    public var errorDescription: String? {
        let text: String
        switch self {
        case .unknown:
            text = l("FileSystemError_Unknown")
        case .noDiskSpace:
            text = l("FileSystemError_NoDiskSpace")
        }
        return text
    }
}

extension NetworkError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .unknown: return l("unknown_error_message")
        case .serverError: return l("unknown_error_message")
        case .notConnectedToInternet: return l("NetworkError_NotConnectedToInternet")
        case .internationalRoamingOff: return l("NetworkError_InternationalRoamingOff")
        case .serverNotReachable: return l("NetworkError_ServerNotReachable")
        case .connectionLost: return l("NetworkError_ConnectionLost")
        }
    }
}

extension ParsingError: LocalizedError {
    public var errorDescription: String? {
        return l("NetworkError_Parsing")
    }
}

extension PersistenceError: LocalizedError {
    public var errorDescription: String? {
        return l("unknown_error_message")
    }
}
