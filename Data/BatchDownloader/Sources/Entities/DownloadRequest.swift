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
import NetworkSupport

public struct DownloadRequest: Hashable, Sendable {
    public static let downloadResumeDataExtension = "resume"

    public let url: URL
    public let resumeURL: URL
    public let destinationURL: URL

    public init(url: URL, destinationURL: URL) {
        self.url = url
        resumeURL = destinationURL.appendingPathExtension(Self.downloadResumeDataExtension)
        self.destinationURL = destinationURL
    }

    public var request: URLRequest {
        URLRequest(url: url)
    }
}

public struct DownloadBatchRequest: Hashable, Sendable {
    public let requests: [DownloadRequest]
    public init(requests: [DownloadRequest]) {
        self.requests = requests
    }
}

extension NetworkSession {
    func downloadTask(with request: DownloadRequest) -> NetworkSessionDownloadTask {
        if let data = try? Data(contentsOf: request.resumeURL) {
            return downloadTask(withResumeData: data)
        } else {
            return downloadTask(with: URLRequest(url: request.url))
        }
    }
}
