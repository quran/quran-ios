//
//  Utilities.swift
//
//
//  Created by Mohamed Afifi on 2021-12-31.
//

import Foundation

extension NetworkSession {
    func tasks() async -> ([NetworkSessionDataTask], [NetworkSessionUploadTask], [NetworkSessionDownloadTask]) {
        await withCheckedContinuation { continuation in
            getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
                continuation.resume(returning: (dataTasks, uploadTasks, downloadTasks))
            }
        }
    }
}
