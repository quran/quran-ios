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
        // Releasing `asset` stops its remote load once no other player shares it.
    }

    init(asset: PlayerAsset, knownDuration: TimeInterval? = nil) {
        self.asset = asset
        playerItem = AVPlayerItem(asset: asset.urlAsset)
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

        if let knownDuration {
            duration = knownDuration
            return
        }

        // With precise timing, AVFoundation may scan (or download) the whole file
        // to answer the duration, so never read it synchronously on the main thread.
        // Capture only the `AVURLAsset`: holding `asset` would keep its remote load from being cancelled.
        let urlAsset = asset.urlAsset
        durationTask = Task { [weak self] in
            let duration = Self.seconds(ofLoadedDuration: try? await urlAsset.load(.duration))
            guard !Task.isCancelled, let self else {
                return
            }
            self.duration = duration
            onDurationLoaded?(duration)
        }
    }

    // MARK: Internal

    var onRateChanged: (@Sendable @MainActor (Float) -> Void)?
    var onDurationLoaded: (@Sendable @MainActor (TimeInterval) -> Void)?

    let asset: PlayerAsset
    let playerItem: AVPlayerItem

    /// The file's duration, or `nil` while it loads.
    private(set) var duration: TimeInterval?

    var currentTime: TimeInterval {
        player.currentTime().seconds
    }

    /// Zero for a failed or non-numeric load, so playback moves past the file. The load returns
    /// `.indefinite` without throwing, e.g. when a server doesn't answer the byte-range probe with a 206.
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
