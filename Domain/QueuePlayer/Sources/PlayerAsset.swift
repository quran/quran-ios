//
//  PlayerAsset.swift
//  QueuePlayer
//
//  Created by Mohamed Afifi on 2026-10-09.
//

import AVFoundation

/// A file's asset, shared by the players built for seeks within that file.
///
/// With precise timing, a new asset can't play until it scans (or, streaming, downloads) the
/// whole file; a new player on an asset that already did starts at once.
final class PlayerAsset {
    // MARK: Lifecycle

    init(url: URL) {
        urlAsset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    }

    deinit {
        // Runs once no player uses the asset, so it never stops a load that a newer player
        // waits on. `load(_:)` ignores Task cancellation, so stop a remote load (and its
        // download) here. Not for local files: their scan can't be interrupted, and a cancelled
        // load would make the Task drop the last asset reference on the main actor, where
        // `AVURLAsset`'s dealloc blocks until the scan ends.
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
