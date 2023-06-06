//
//  NowPlayingUpdater.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import MediaPlayer
import QueuePlayer

// TODO: Use MainActor
class NowPlayingUpdater {
    private let center: MPNowPlayingInfoCenter
    private var nowPlayingInfo: [String: Any]? {
        didSet {
            center.nowPlayingInfo = nowPlayingInfo
        }
    }

    init(center: MPNowPlayingInfoCenter) {
        self.center = center
    }

    func clear() {
        nowPlayingInfo = nil
    }

    func update(duration: TimeInterval) {
        update([MPMediaItemPropertyPlaybackDuration: duration])
    }

    func update(elapsedTime: TimeInterval) {
        update([MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedTime])
    }

    func update(info: PlayerItemInfo) {
        update([MPMediaItemPropertyTitle: info.title,
                MPMediaItemPropertyArtist: info.artist])
        if let artwork = info.artwork {
            update([MPMediaItemPropertyArtwork: artwork])
        }
    }

    func update(rate: Float) {
        update([MPNowPlayingInfoPropertyPlaybackRate: rate])
    }

    func update(count: Int) {
        update([MPNowPlayingInfoPropertyPlaybackQueueCount: count])
    }

    func update(playingIndex: Int) {
        update([MPNowPlayingInfoPropertyPlaybackQueueIndex: playingIndex])
    }

    private func update(_ values: [String: Any]) {
        var info = nowPlayingInfo ?? [:]
        for (key, value) in values {
            info[key] = value
        }
        nowPlayingInfo = info
    }
}
