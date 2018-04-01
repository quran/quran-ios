//
//  DefaultAudioPlayer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/25/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation
import QueuePlayer

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
        player.oneStepForward()
    }

    func goBackward() {
        player.oneStepBackward()
    }

    func stopPlaybackNotifications() {
        player.onPlaybackEnded = nil
        player.onPlayerItemChangedTo = nil
        player.onPlaybackStartingTimeFrame = nil
        player.onPlaybackRateChanged = nil
    }
}
