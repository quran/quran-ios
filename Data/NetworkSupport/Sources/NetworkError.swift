//
//  NetworkError.swift
//  SwinjectMVVMExample
//
//  Created by Yoichi Tagaya on 8/22/15.
//  Copyright © 2015 Swinject Contributors. All rights reserved.
//

import Foundation
import Localization

public enum NetworkError: Error {
    /// Unknown or not supported error.
    case unknown(Error?)

    /// Not connected to the internet.
    case notConnectedToInternet

    /// International data roaming turned off.
    case internationalRoamingOff

    /// Connection is lost.
    case connectionLost

    /// Cannot reach the server.
    case serverNotReachable

    case serverError(String)

    // MARK: Lifecycle

    public init(error: Error) {
        if let error = error as? NetworkError {
            self = error
        } else if let error = error as? URLError {
            switch error.code {
            case .timedOut, .cannotFindHost, .cannotConnectToHost:
                self = .serverNotReachable
            case .networkConnectionLost:
                self = .connectionLost
            case .dnsLookupFailed:
                self = .serverNotReachable
            case .notConnectedToInternet:
                self = .notConnectedToInternet
            case .internationalRoamingOff:
                self = .internationalRoamingOff
            default:
                self = .unknown(error)
            }
        } else {
            self = .unknown(error)
        }
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
