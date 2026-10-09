//
//  PlayerAsset.swift
//  QueuePlayer
//
//  Created by Mohamed Afifi on 2026-10-09.
//

import AVFoundation

/// A file's asset, shared by the players built for seeks within that file.
final class PlayerAsset {
    // MARK: Lifecycle

    init(url: URL) {
        urlAsset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    }

    deinit {
        // `load(_:)` ignores Task cancellation, so stop a remote load here. Not a local one: releasing
        // a mid-scan local asset on the main actor blocks in `AVURLAsset`'s dealloc until the scan ends.
        if !urlAsset.url.isFileURL {
            urlAsset.cancelLoading()
        }
    }

    // MARK: Internal

    let urlAsset: AVURLAsset

    var url: URL {
        urlAsset.url
    }
}
