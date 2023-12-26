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
import Utilities

public struct DownloadRequest: Hashable, Sendable {
    // MARK: Lifecycle

    public init(url: URL, destination: RelativeFilePath) {
        self.url = url
        self.destination = destination
    }

    // MARK: Public

    public let url: URL
    public let destination: RelativeFilePath

    public var resumePath: RelativeFilePath { destination.appendingPathExtension(Self.downloadResumeDataExtension) }

    public var request: URLRequest {
        URLRequest(url: url)
    }

    // MARK: Private

    private static let downloadResumeDataExtension = "resume"
}

public struct DownloadBatchRequest: Hashable, Sendable {
    // MARK: Lifecycle

    public init(requests: [DownloadRequest]) {
        self.requests = requests
    }

    // MARK: Public

    public let requests: [DownloadRequest]
}

extension NetworkSession {
    func downloadTask(with request: DownloadRequest) -> NetworkSessionDownloadTask {
        if let data = try? Data(contentsOf: request.resumePath) {
            return downloadTask(withResumeData: data)
        } else {
            return downloadTask(with: URLRequest(url: request.url))
        }
    }
}
