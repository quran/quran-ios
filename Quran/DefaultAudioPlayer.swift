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

    func prepareToPlayForFirstTime(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber, playBlock: () -> Void)

    func onPlayingStopped()
}

extension DefaultAudioPlayer {

    func prepareToPlayForFirstTime(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber, playBlock: () -> Void) {
        playBlock()
    }

    func play(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) {
        Queue.main.async {
            let items = self.playerItemsForQari(qari, startAyah: startAyah, endAyah: endAyah)
            print(items)
            self.playingItems = items

            self.player.removeAllItems()
            items.forEach { self.player.insertItem(cast($0), afterItem: nil) }

            self.willStartPlaying(qari: qari, startAyah: startAyah, endAyah: endAyah)
            self.prepareToPlayForFirstTime(qari: qari, startAyah: startAyah, endAyah: endAyah) { [weak self] in self?.player.play() }
        }
    }

    func pause() {
        self.player.pause()
    }

    func resume() {
        self.player.play()
    }

    func stop() {
        _onPlayingStopped()
    }

    func playNextAudio(starting timeInSeconds: Double) {
        startFromBegining()

        player.advanceToNextItem()
        seekTo(timeInSeconds)
        player.play()
    }

    func playPreviousAudio(starting timeInSeconds: Double) {
        guard let currentItem = player.currentItem,
            var index = playingItems.indexOf(currentItem) else {
            return
        }

        index -= 1
        guard index >= 0 else {
            stop()
            return
        }

        startFromBegining()

        removeCurrentItemObserver()
        player.removeAllItems()
        for i in index..<playingItems.count {
            player.insertItem(cast(playingItems[i]), afterItem: nil)
        }
        addCurrentItemObserver()
        seekTo(timeInSeconds)
        _currentItemChanged(player.currentItem)
        player.play()
    }

    private func startFromBegining() {
        player.pause()
        seekTo(0)
    }

    func seekTo(timeInSeconds: Double) {
        let time = CMTime(seconds: timeInSeconds, preferredTimescale: 1000)
        player.seekToTime(time)
    }

    func onPlayerItemChangedTo(newItem: AVPlayerItem) {
    }

    private func willStartPlaying(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) {
        addCurrentItemObserver()
    }

    func onPlayingStopped() {
    }

    private func _onPlayingStopped() {
        player.removeAllItems()
        playingItems = []
        inAudioSession = false
        removeCurrentItemObserver()
        onPlayingStopped()
        delegate?.onPlaybackEnded()
    }

    private func addCurrentItemObserver() {
        observingObject.observe(retainedObservable: player, keyPath: "currentItem", options: [.New]) { [weak self] (observable, change) in
            self?._currentItemChanged(change.newValue)
        }
    }

    private func _currentItemChanged(newValue: AVPlayerItem?) {
        guard let newValue = newValue else {
            if inAudioSession {
                _onPlayingStopped()
            }
            return
        }
        inAudioSession = true
        onPlayerItemChangedTo(newValue)
    }

    private func removeCurrentItemObserver() {
        self.observingObject.unobserve(self.player, keyPath: "currentItem")
    }
}
