//
//  PlayerAsset.swift
//  QueuePlayer
//
//  Created by Mohamed Afifi on 2026-10-09.
//

import AVFoundation

/// A file's asset, shared by the players built for seeks within that file, so a seek doesn't
/// read (or, streaming, fetch) the file's start and its duration again.
final class PlayerAsset {
    // MARK: Lifecycle

    init(url: URL) {
        // No precise timing (`AVURLAssetPreferPreciseDurationAndTimingKey`): with it, an item can't
        // play until AVFoundation scans the whole MP3 and, streaming, downloads it. Husary's 191 MB
        // Al-Baqarah took 7.3-9.8 s to start instead of 0.3 s; a 17 MB sura streamed at 2 MB/s,
        // 11.8 s instead of 0.47 s. The reciter files are CBR (266 of 267 sampled across 89
        // reciters; the other has a Xing TOC), so the estimates are close: seeks land 1-3 MP3
        // frames (26-78 ms) off, shifting verse highlights by at most ~78 ms, and durations differ
        // by at most 78 ms over 3.3 h. A frame that ends with its file still ends when the item
        // does, should its estimated duration run long. Leave the key out rather than passing `false`,
        // which makes loading a CAF file's duration fail.
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
