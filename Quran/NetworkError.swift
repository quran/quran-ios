//
//  NetworkError.swift
//  SwinjectMVVMExample
//
//  Created by Yoichi Tagaya on 8/22/15.
//  Copyright © 2015 Swinject Contributors. All rights reserved.
//

import Foundation

public enum NetworkError: ErrorType, CustomStringConvertible {
    /// Unknown or not supported error.
    case Unknown

    /// Not connected to the internet.
    case NotConnectedToInternet

    /// International data roaming turned off.
    case InternationalRoamingOff

    /// Connection is lost.
    case ConnectionLost

    /// Cannot reach the server.
    case ServerNotReachable

    internal init(error: ErrorType) {
        if let error = error as? NSURLError {
            switch error {
            case .TimedOut, .CannotFindHost, .CannotConnectToHost:
                self = .ServerNotReachable
            case .NetworkConnectionLost:
                self = .ConnectionLost
            case .DNSLookupFailed:
                self = .ServerNotReachable
            case .NotConnectedToInternet:
                self = .NotConnectedToInternet
            case .InternationalRoamingOff:
                self = .InternationalRoamingOff
            default:
                self = .Unknown
            }
        } else {
            self = .Unknown
        }
    }

    public var description: String {
        let text: String
        switch self {
        case .Unknown:
            text = NSLocalizedString("NetworkError_Unknown", comment: "Error description")
        case .NotConnectedToInternet:
            text = NSLocalizedString("NetworkError_NotConnectedToInternet", comment: "Error description")
        case .InternationalRoamingOff:
            text = NSLocalizedString("NetworkError_InternationalRoamingOff", comment: "Error description")
        case .ServerNotReachable:
            text = NSLocalizedString("NetworkError_ServerNotReachable", comment: "Error description")
        case .ConnectionLost:
            text = NSLocalizedString("NetworkError_ConnectionLost", comment: "Error description")
        }
        return text
    }
}
