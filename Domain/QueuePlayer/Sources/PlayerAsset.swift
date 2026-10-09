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
        // No precise timing: it makes an item wait for a full scan (or download) of the MP3. Leave the
        // key out rather than passing `false`, which makes loading a CAF file's duration fail.
        urlAsset = AVURLAsset(url: url)
    }

    deinit {
        // `load(_:)` ignores Task cancellation, so stop a remote load here. Not a local one: releasing
        // a mid-load local asset on the main actor blocks in `AVURLAsset`'s dealloc until the load ends.
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
