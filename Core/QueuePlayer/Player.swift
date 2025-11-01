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
    }

    init(url: URL) {
        asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        playerItem = AVPlayerItem(asset: asset)
        playerItem.audioTimePitchAlgorithm = .timeDomain
        player = AVPlayer(playerItem: playerItem)

        rateObservation = player.observe(\AVPlayer.rate, options: [.new]) { [weak self] _, change in
            if let rate = change.newValue {
                guard let self else { return }
                Task {
                    await self.onRateChanged?(rate)
                }
            }
        }
    }

    // MARK: Internal

    var onRateChanged: (@Sendable @MainActor (Float) -> Void)?

    let playerItem: AVPlayerItem

    var currentTime: TimeInterval {
        player.currentTime().seconds
    }

    var duration: TimeInterval {
        asset.duration.seconds
    }

    func play() {
        player.play()
        player.rate = currentRate
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
    }
    
    // NEW: set playback speed; if currently playing, apply immediately
    func setRate(_ rate: Float) {
        currentRate = rate
        if player.rate != 0 {
            player.rate = rate
        }
    }

    func seek(to timeInSeconds: TimeInterval) {
        pause()
        player.seek(to: timeInSeconds)
        play()
    }

    // MARK: Private

    private let asset: AVURLAsset
    private let player: AVPlayer
    private var currentRate: Float = 1.0

    private var rateObservation: NSKeyValueObservation? {
        didSet { oldValue?.invalidate() }
    }
}

private extension AVPlayer {
    func seek(to timeInSeconds: TimeInterval) {
        let time = CMTime(seconds: timeInSeconds, preferredTimescale: 1000)
        seek(to: time)
    }
}
