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

    let url: URL
    let resumePath: String
    let destinationPath: String
    var status: Status

    public init(url: URL, resumePath: String, destinationPath: String, status: Status/* = false*/) {
        self.url = url
        self.resumePath = resumePath
        self.destinationPath = destinationPath
        self.status = status
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
