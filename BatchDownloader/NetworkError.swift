// //swiftlint:disable:this file_header
//  NetworkError.swift
//  SwinjectMVVMExample
//
//  Created by Yoichi Tagaya on 8/22/15.
//  Copyright © 2015 Swinject Contributors. All rights reserved.
//

import Foundation

public enum NetworkError: Error {
    /// Unknown or not supported error.
    case unknown(Error)

    /// Not connected to the internet.
    case notConnectedToInternet

    /// International data roaming turned off.
    case internationalRoamingOff

    /// Connection is lost.
    case connectionLost

    /// Cannot reach the server.
    case serverNotReachable

    case serverError(String)

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
