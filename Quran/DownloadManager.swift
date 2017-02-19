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

    func getCurrentTasks(_ completion: @escaping (_ downloads: [DownloadNetworkResponse]) -> Void)

    func download(_ requests: [Download]) -> [DownloadNetworkResponse]
}

extension DownloadManager {

    func download(_ requestDetails: [DownloadRequest]) -> [DownloadNetworkResponse] {

        let requests: [Download] = requestDetails.map { details in
            var request = URLRequest(url: details.url)
            request.httpMethod = details.method.rawValue
            return Download(url: details.url, resumePath: details.resumePath, destinationPath: details.destinationPath)
        }
        return download(requests)
    }
}
