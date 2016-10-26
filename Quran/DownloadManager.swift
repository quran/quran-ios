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

    func getCurrentTasks(_ completion: @escaping (_ downloads: [DownloadNetworkRequest]) -> Void)

    func download(_ requests: [(request: URLRequest, destination: String, resumeDestination: String)]) -> [DownloadNetworkRequest]
}

extension DownloadManager {

    func download(_ requestDetails: [(
        method: HTTPMethod,
        url: Foundation.URL,
        headers: [String: String]?,
        destination: String,
        resumeDestination: String)]) -> [DownloadNetworkRequest] {

        let requests: [(request: URLRequest, destination: String, resumeDestination: String)] = requestDetails.map { details in
            var request = URLRequest(url: details.url)
            request.httpMethod = details.method.rawValue
            return (request: request, destination: details.destination, resumeDestination: details.resumeDestination)
        }
        return download(requests)
    }
}
