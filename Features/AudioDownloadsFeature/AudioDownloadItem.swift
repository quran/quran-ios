//
//  AudioDownloadItem.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/4/21.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import Foundation
import NoorUI
import QuranAudio

struct AudioDownloadItem: Hashable, Comparable {
    struct Size: Hashable {
        let downloadedSizeInBytes: UInt64
        let downloadedSuraCount: Int
        let surasCount: Int
    }

    // MARK: Internal

    enum DownloadingProgress: Hashable {
        case loading
        case notDownloading
        case downloading(Float)
    }

    let reciter: Reciter
    let name: String
    let size: Size?
    let downloading: DownloadingProgress

    var isDownloaded: Bool {
        size?.downloadedSuraCount == size?.surasCount
    }

    var downloadState: DownloadState {
        switch downloading {
        case .loading:
            return .downloaded // hide the button
        case .downloading(let progress):
            return progress < 0.001 ? .pendingDownloading : .downloading(progress: progress)
        case .notDownloading:
            return isDownloaded ? .downloaded : .notDownloaded
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        guard let lhsSize = lhs.size, let rhsSize = rhs.size else {
            return lhs.name < rhs.name
        }
        if lhsSize.downloadedSizeInBytes != rhsSize.downloadedSizeInBytes {
            return lhsSize.downloadedSizeInBytes > rhsSize.downloadedSizeInBytes
        }
        return lhs.name < rhs.name
    }
}
