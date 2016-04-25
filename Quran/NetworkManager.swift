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
    func performRequest(
        method method: HTTPMethod,
               url: NSURL,
               parameters: [String: AnyObject]?,
               parameterEncoding: NetworkRequestParameterEncoding,
               headers: [String: String]?)
}
