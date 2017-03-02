//
//  Download.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/14/17.
//  Copyright © 2017 Quran.com. All rights reserved.
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
