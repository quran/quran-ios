//
//  DownloadRequest.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/11/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

struct DownloadRequest {
    let method: HTTPMethod
    let headers: [String: String]?

    let url: URL
    let resumePath: String
    let destinationPath: String

    init(method: HTTPMethod, headers: [String: String]? = nil, download: Download) {
        self.method = method
        self.headers = headers
        url = download.url
        resumePath = download.resumePath
        destinationPath = download.destinationPath

    }
}
