//
//  Errors+Description.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/28/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//

import BatchDownloader
import Foundation
import Localization
import NetworkSupport
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

extension PersistenceError: LocalizedError {
    public var errorDescription: String? {
        l("unknown_error_message")
    }
}
