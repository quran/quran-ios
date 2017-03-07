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

struct TranslationFull: Equatable {
    let translation: Translation
    var downloaded: Bool
    var downloadResponse: DownloadNetworkResponse?

    static func==(lhs: TranslationFull, rhs: TranslationFull) -> Bool {
        return lhs.translation == rhs.translation
    }
}

extension TranslationFull {
    var downloadState: DownloadState {
        if downloaded {
            return .downloaded
        }
        guard let response = downloadResponse else {
            return .notDownloaded
        }
        return Float(response.progress.fractionCompleted).downloadState
    }
}

extension Float {

    var downloadState: DownloadState {
        if abs(self) < 0.001 {
            return .pending
        } else {
            return .downloading(progress: self)
        }
    }
}
