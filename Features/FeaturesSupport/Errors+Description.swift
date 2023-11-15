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
            text = l("error.message.general")
        case .noDiskSpace:
            text = l("error.message.no_disk_space")
        }
        return text
    }
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknown, .serverError, .serverNotReachable:
            return l("error.message.general")
        case .notConnectedToInternet:
            return l("error.message.not_connected_to_internet")
        case .internationalRoamingOff:
            return l("error.message.international_roaming_off")
        case .connectionLost:
            return l("error.message.connection_lost")
        }
    }
}

extension PersistenceError: LocalizedError {
    public var errorDescription: String? {
        l("error.message.general")
    }
}
