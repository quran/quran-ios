// //swiftlint:disable:this file_header
//  NetworkError.swift
//  SwinjectMVVMExample
//
//  Created by Yoichi Tagaya on 8/22/15.
//  Copyright © 2015 Swinject Contributors. All rights reserved.
//

import Foundation

public enum NetworkError: QuranError {
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

    case parsing(String)

    case serverError(String)

    internal init(error: Error) {
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

    public var localizedDescriptionv2: String {
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
        case .parsing:
            text = NSLocalizedString("NetworkError_Parsing", comment: "When a parsing error occurs")
        }
        return text
    }
}
