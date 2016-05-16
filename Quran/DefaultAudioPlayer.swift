//
//  DefaultAudioPlayer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/16/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import AVFoundation
import KVOController_Swift

protocol DefaultAudioPlayer: class, AudioPlayer {

    var player: AVQueuePlayer { get }

    func playerItemsForQari(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [AVPlayerItem]

    var inAudioSession: Bool { get set }

    var playingItems: [AVPlayerItem] { get set }

    var observingObject: NSObject { get }

    func onPlayerItemChangedTo(newItem: AVPlayerItem)
}

extension DefaultAudioPlayer {

    func play(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) {
        Queue.main.async {
            let items = self.playerItemsForQari(qari, startAyah: startAyah, endAyah: endAyah)
            self.playingItems = items

            self.player.removeAllItems()
            for item in items {
                self.player.insertItem(cast(item), afterItem: nil)
            }
            self.willStartPlaying(qari: qari, startAyah: startAyah, endAyah: endAyah)
            self.player.play()
        }
    }

    func pause() {
        self.player.pause()
    }

    func resume() {
        self.player.play()
    }

    func stop() {
        self.player.removeAllItems()
        self.onPlayingStopped()
    }

    func playNextAudio() {
        player.advanceToNextItem()
        player.seekToTime(kCMTimeZero, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }

    func playPreviousAudio() {
        guard let currentItem = player.currentItem,
            var index = playingItems.indexOf(currentItem) else {
            return
        }

        index -= 1
        guard index >= 0 else {
            stop()
            return
        }

        removeCurrentItemObserver()
        player.pause()
        player.removeAllItems()
        player.seekToTime(kCMTimeZero, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        for i in index..<playingItems.count {
            player.insertItem(cast(playingItems[i]), afterItem: nil)
        }
        addCurrentItemObserver()
        player.seekToTime(kCMTimeZero, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        player.play()
    }

    func onPlayerItemChangedTo(newItem: AVPlayerItem) {
    }

    private func willStartPlaying(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) {
        addCurrentItemObserver()
    }

    private func onPlayingStopped() {
        playingItems = []
        self.inAudioSession = false
        removeCurrentItemObserver()
        self.delegate?.onPlaybackEnded()
    }

    private func addCurrentItemObserver() {
        observingObject.observe(retainedObservable: player, keyPath: "currentItem",
                                options: [.New]) { [weak self] (observable, change: ChangeData<AVPlayerItem>) in
                                    guard let `self` = self else {
                                        return
                                    }

                                    guard let newValue = change.newValue else {
                                        print("New item: nil")
                                        if self.inAudioSession {
                                            self.onPlayingStopped()
                                        }
                                        return
                                    }
                                    print("New item: \(self.playingItems.indexOf(newValue))")

                                    self.inAudioSession = true
                                    self.onPlayerItemChangedTo(newValue)
        }
    }

    private func removeCurrentItemObserver() {
        self.observingObject.unobserve(self.player, keyPath: "currentItem")
    }
}
