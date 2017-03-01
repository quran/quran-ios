//
//  TranslationFull.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/1/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

enum DownloadState {
    case notDownloaded
    case pending
    case downloading(progress: Float)
    case downloaded
}

struct TranslationFull {
    let translation: Translation
    var downloaded: Bool
    var downloadResponse: DownloadNetworkResponse?
}

extension TranslationFull {
    var downloadState: DownloadState {
        if downloaded {
            return .downloaded
        }
        guard let response = downloadResponse else {
            return .notDownloaded
        }
        if abs(response.progress.fractionCompleted - 0.001) < 0 {
            return .pending
        } else {
            return .downloading(progress: Float(response.progress.fractionCompleted))
        }
    }
}
