//
//  Player.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 5/4/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AVFoundation

@MainActor
final class Player {
    // MARK: Lifecycle

    deinit {
        rateObservation?.invalidate()
        durationTask?.cancel()
        // `load(_:)` ignores Task cancellation, so stop a remote load (and its download) here.
        // Not for local files: their scan can't be interrupted, and a cancelled load would make
        // the Task drop the last asset reference on the main actor, where `AVURLAsset`'s dealloc
        // blocks until the scan ends.
        if !asset.url.isFileURL {
            asset.cancelLoading()
        }
    }

    init(url: URL) {
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        self.asset = asset
        playerItem = AVPlayerItem(asset: asset)
        playerItem.audioTimePitchAlgorithm = .spectral
        player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false

        rateObservation = player.observe(\AVPlayer.rate, options: [.new]) { [weak self] _, change in
            if let rate = change.newValue {
                guard let self else { return }
                Task {
                    await self.onRateChanged?(rate)
                }
            }
        }

        // With precise timing, AVFoundation may scan (or download) the whole file
        // to answer the duration, so never read it synchronously on the main thread.
        durationTask = Task { [weak self] in
            // `load(_:)` ignores cancellation, so a player discarded before this runs skips the scan.
            guard !Task.isCancelled else {
                return
            }
            let duration = Self.seconds(ofLoadedDuration: try? await asset.load(.duration))
            guard !Task.isCancelled, let self else {
                return
            }
            self.duration = duration
            onDurationLoaded?()
        }
    }

    // MARK: Internal

    var onRateChanged: (@Sendable @MainActor (Float) -> Void)?
    var onDurationLoaded: (@Sendable @MainActor () -> Void)?

    let playerItem: AVPlayerItem

    /// The file's duration, or `nil` while it loads.
    private(set) var duration: TimeInterval?

    var currentTime: TimeInterval {
        player.currentTime().seconds
    }

    /// A failed or non-numeric load reports zero, so playback moves past the file.
    /// The load returns `.indefinite` without throwing when, for example, a server
    /// doesn't answer AVFoundation's byte-range probe with a 206.
    static func seconds(ofLoadedDuration duration: CMTime?) -> TimeInterval {
        guard let duration, duration.isNumeric else {
            return 0
        }
        return duration.seconds
    }

    // MARK: Internal helpers (read-only)

    var isPlaying: Bool {
        player.rate != 0
    }

    func play(rate: Float) {
        player.playImmediately(atRate: rate)
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
    }

    func setRate(_ rate: Float) {
        player.rate = rate
    }

    func seek(to timeInSeconds: TimeInterval, rate: Float) {
        pause()
        player.seek(to: timeInSeconds)
        play(rate: rate)
    }

    // MARK: Private

    private let asset: AVURLAsset
    private let player: AVPlayer

    private var rateObservation: NSKeyValueObservation? {
        didSet { oldValue?.invalidate() }
    }

    private var durationTask: Task<Void, Never>?
}

private extension AVPlayer {
    func seek(to timeInSeconds: TimeInterval) {
        let time = CMTime(seconds: timeInSeconds, preferredTimescale: 1000)
        seek(to: time)
    }
}
