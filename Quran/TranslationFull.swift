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
        return response.progress.downloadState
    }
}

extension Progress {

    var downloadState: DownloadState {
        print(fractionCompleted)
        if abs(fractionCompleted) < 0.001 {
            return .pending
        } else {
            return .downloading(progress: Float(fractionCompleted))
        }
    }
}
