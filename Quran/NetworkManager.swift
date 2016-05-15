//
//  NetworkManager.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
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

protocol NetworkManager: class {

    var backgroundSessionCompletionHandler: (() -> Void)? { get set }

    func getCurrentTasks(completion: (downloads: [Request]) -> Void)

    func download(request: NSURLRequest, destination: String, resumeDestination: String) -> Request
}

extension NetworkManager {

    func download(
        method: HTTPMethod,
        url: NSURL,
        headers: [String: String]? = nil,
        destination: String,
        resumeDestination: String) -> Request {

        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = method.rawValue
        return download(request, destination: destination, resumeDestination: resumeDestination)
    }
}
