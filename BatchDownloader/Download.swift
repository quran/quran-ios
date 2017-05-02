//
//  Download.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/14/17.
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

public struct Download {

    public enum Status: Int {
        case downloading = 0
        case completed   = 1
        // case failed      = 2 // we shouldn't keep a failed download
        case pending     = 3
    }

    public let batchId: Int64
    public let request: DownloadRequest

    public var status: Status
    public var taskId: Int?

    public init(taskId: Int? = nil, request: DownloadRequest, status: Status = .downloading, batchId: Int64) {
        self.taskId  = taskId
        self.request = request
        self.status  = status
        self.batchId = batchId
    }
}

public struct DownloadBatch {
    public let id: Int64
    public let downloads: [Download]
    public init(id: Int64, downloads: [Download]) {
        self.id = id
        self.downloads = downloads
    }
}
