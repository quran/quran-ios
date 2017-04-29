//
//  DownloadManager.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation
import PromiseKit

public enum HTTPMethod: String {
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

public protocol DownloadManager: class {

    var backgroundSessionCompletionHandler: (() -> Void)? { get set }

    func getOnGoingDownloads() -> Promise<[DownloadNetworkBatchResponse]>

    func download(_ requests: [Download]) -> [DownloadNetworkResponse]
}

extension DownloadManager {

    public func download(_ requestDetails: [DownloadRequest]) -> [DownloadNetworkResponse] {

        let requests: [Download] = requestDetails.map { details in
            var request = URLRequest(url: details.url)
            request.httpMethod = details.method.rawValue
            return Download(url: details.url, resumePath: details.resumePath, destinationPath: details.destinationPath)
        }
        return download(requests)
    }
}
