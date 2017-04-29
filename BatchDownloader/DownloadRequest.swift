//
//  DownloadRequest.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/11/17.
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

public struct DownloadRequest {
    public let method: HTTPMethod
    public let headers: [String: String]?

    public let url: URL
    public let resumePath: String
    public let destinationPath: String

    public init(method: HTTPMethod, headers: [String: String]? = nil, download: Download) {
        self.method = method
        self.headers = headers
        url = download.url
        resumePath = download.resumePath
        destinationPath = download.destinationPath

    }
}
