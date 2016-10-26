//
//  DefaultAudioPlayer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/25/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol DefaultAudioPlayer: class, AudioPlayer {

    var player: QueuePlayer { get }
}


extension DefaultAudioPlayer {

    func onPlaybackEnded() -> () -> Void {
        return { [weak self] () -> Void in
            self?.delegate?.onPlaybackEnded()
            self?.stopPlaybackNotifications()
        }
    }

    func onPlaybackRateChanged() -> (Bool) -> Void {
        return { [weak self] playing in
            if playing {
                self?.delegate?.onPlaybackResumed()
            } else {
                self?.delegate?.onPlaybackPaused()
            }
        }
    }

    func pause() {
        player.pause()
    }

    func resume() {
        player.resume()
    }

    func stop() {
        player.stop()
        stopPlaybackNotifications()
    }

    func goForward() {
        player.onStepForward()
    }

    func goBackward() {
        player.onStepBackward()
    }

    func stopPlaybackNotifications() {
        player.onPlaybackEnded = nil
        player.onPlayerItemChangedTo = nil
        player.onPlaybackStartingTimeFrame = nil
        player.onPlaybackRateChanged = nil
    }
}
