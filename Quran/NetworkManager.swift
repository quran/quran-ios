//
//  NetworkManager.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

enum HTTPMethod {
    case OPTIONS
    case GET
    case HEAD
    case POST
    case PUT
    case PATCH
    case DELETE
    case TRACE
    case CONNECT
}

enum NetworkRequestParameterEncoding {
    case URL
    case URLEncodedInURL
    case JSON
}

protocol NetworkManager {

    var startRequestsImmediately: Bool { get set }

    func download(
        method: HTTPMethod,
        url: NSURL,
        parameters: [String: AnyObject]?,
        parameterEncoding: NetworkRequestParameterEncoding,
        headers: [String: String]?,
        completionHandler: (NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?) -> Void) -> NetworkRequest
}

extension NetworkManager {

    func download(
        method: HTTPMethod,
        url: NSURL,
        parameters: [String: AnyObject]? = nil,
        parameterEncoding: NetworkRequestParameterEncoding = .URL,
        headers: [String: String]? = nil,
        completionHandler: (NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?) -> Void) -> NetworkRequest {
        return download(method,
                        url: url,
                        parameters: parameters,
                        parameterEncoding: parameterEncoding,
                        headers: headers,
                        completionHandler: completionHandler)
    }
}
