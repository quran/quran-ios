//
//  DownloadManager.swift
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

protocol DownloadManager: class {

    var backgroundSessionCompletionHandler: (() -> Void)? { get set }

    func getCurrentTasks(completion: (downloads: [Request]) -> Void)

    func download(requests: [(request: NSURLRequest, destination: String, resumeDestination: String)]) -> [Request]
}

extension DownloadManager {

    func download(requestDetails: [(
        method: HTTPMethod,
        url: NSURL,
        headers: [String: String]?,
        destination: String,
        resumeDestination: String)]) -> [Request] {

        let requests: [(request: NSURLRequest, destination: String, resumeDestination: String)] = requestDetails.map { details in
            let request = NSMutableURLRequest(URL: details.url)
            request.HTTPMethod = details.method.rawValue
            return (request: request, destination: details.destination, resumeDestination: details.resumeDestination)
        }
        return download(requests)
    }
}
