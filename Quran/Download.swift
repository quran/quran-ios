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

struct Download {

    enum Status: Int {
        case downloading
        case completed
        case failed
    }

    var taskId: Int?
    let url: URL
    let resumePath: String
    let destinationPath: String
    var status: Status
    var batchId: Int64?

    public init(taskId: Int? = nil, url: URL, resumePath: String, destinationPath: String, status: Status = .downloading, batchId: Int64? = nil) {
        self.taskId = taskId
        self.url = url
        self.resumePath = resumePath
        self.destinationPath = destinationPath
        self.status = status
        self.batchId = batchId
    }
}

struct DownloadBatch {
    let downloads: [Download]

    var status: Download.Status {
        var failed = false
        for download in downloads {
            if download.status == .failed {
                failed = true
            } else if download.status == .downloading {
                return .downloading
            }
        }
        return failed ? .failed : .completed
    }
}
