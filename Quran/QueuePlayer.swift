//
//  QueuePlayer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import AVFoundation
import KVOController_Swift

class QueuePlayer: NSObject {

    let player: AVQueuePlayer = AVQueuePlayer()

    override init() {
        let _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord,
                                                                 withOptions: [.DefaultToSpeaker, .AllowBluetooth])
        player.actionAtItemEnd = .Advance
    }

    private (set) var playingItemBoundaries: [AVPlayerItem: [Double]] = [:]
    var playingItems: [AVPlayerItem] = []

    var onPlaybackEnded: (() -> Void)?
    var onPlayerItemChangedTo: (AVPlayerItem? -> Void)?
    var onPlaybackStartingTimeFrame: ((item: AVPlayerItem, timeIndex: Int) -> Void)?

    private var currentTimeIndex: Int? {
        didSet {
            print(currentTimeIndex)
        }
    }

    private var timeObserver: AnyObject? {
        didSet {
            if let oldValue = oldValue {
                player.removeTimeObserver(oldValue)
            }
        }
    }

    func play(startTimeInSeconds startTimeInSeconds: Double = 0, items: [AVPlayerItem], playingItemBoundaries: [AVPlayerItem: [Double]]) {
        playingItems = items
        self.playingItemBoundaries = playingItemBoundaries

        // enqueue new items
        player.removeAllItems()
        items.forEach { self.player.insertItem($0, afterItem: nil) }

        seekTo(startTimeInSeconds)
        player.play()
        addCurrentItemObserver()
        _currentItemChanged(player.currentItem)
    }

    func pause() {
        player.pause()
    }

    func resume() {
        player.play()
    }

    func stop() {
        stopPlayback()
    }

    func onStepForward() {
        guard let currentItem = player.currentItem,
            let boundaries = playingItemBoundaries[currentItem] else {
            return
        }

        let currentIndex = currentTimeIndex ?? 0

        let newTimeIndex: Int
        if currentIndex + 1 < boundaries.count {
            newTimeIndex = currentIndex + 1
            seekTo(boundaries[newTimeIndex])
        } else {
            newTimeIndex = 0
            playNextAudio(starting: 0)
        }
        currentTimeIndex = newTimeIndex
        handleTimeBoundaryReached()
    }

    func onStepBackward() {
        guard let currentItem = player.currentItem,
            let boundaries = playingItemBoundaries[currentItem] else {
                return
        }

        let currentIndex = currentTimeIndex ?? 0

        let newTimeIndex: Int
        if currentIndex - 1 >= 0 {
            newTimeIndex = currentIndex - 1
            seekTo(boundaries[newTimeIndex])
        } else {

            let index = playingItems.indexOf(currentItem) ?? 0
            guard index > 0 else {
                stop()
                return
            }
            guard let previousBoundaries = playingItemBoundaries[playingItems[index - 1]] else { return }

            newTimeIndex = previousBoundaries.count - 1
            playPreviousAudio(starting: previousBoundaries[newTimeIndex])
        }
        currentTimeIndex = newTimeIndex
        handleTimeBoundaryReached()
    }

    private func playNextAudio(starting timeInSeconds: Double) {
        guard playingItems.last != player.currentItem else {
            stop()
            return
        }

        let oldRate = player.rate

        startFromBegining()
        player.advanceToNextItem()
        seekTo(timeInSeconds)
        player.play()
        player.rate = oldRate
    }

    private func playPreviousAudio(starting timeInSeconds: Double) {
        guard let currentItem = player.currentItem,
            var index = playingItems.indexOf(currentItem) else {
                return
        }

        index -= 1
        guard index >= 0 else {
            stop()
            return
        }

        let oldRate = player.rate

        startFromBegining()

        removeCurrentItemObserver()
        player.removeAllItems()
        for i in index..<playingItems.count {
            player.insertItem(playingItems[i], afterItem: nil)
        }
        addCurrentItemObserver()
        seekTo(timeInSeconds)
        _currentItemChanged(player.currentItem)
        player.play()
        player.rate = oldRate
    }

    private func startFromBegining() {
        player.pause()
        seekTo(0)
    }

    private func seekTo(timeInSeconds: Double) {
        let time = CMTime(seconds: timeInSeconds, preferredTimescale: 1000)
        player.seekToTime(time)
    }

    private func addCurrentItemObserver() {
        observe(retainedObservable: player, keyPath: "currentItem", options: [.New]) { [weak self] (observable, change) in
            self?._currentItemChanged(change.newValue)
        }
    }

    private func _currentItemChanged(newValue: AVPlayerItem?) {
        guard let newValue = newValue else { return }

        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(onCurrentItemReachedEnd),
                                                         name: AVPlayerItemDidPlayToEndTimeNotification,
                                                         object: newValue)
        startBoundaryObserver(newValue)
        notifyPlayerItemChangedTo(newValue)
        handleTimeBoundaryReached()
    }

    func onCurrentItemReachedEnd() {
        // determine to repeat or start next one

        if playingItems.last == player.currentItem {
            // last item finished playing
            stop()
        }
    }

    private func startBoundaryObserver(newItem: AVPlayerItem) {
        guard let times = playingItemBoundaries[newItem] else { return }

        currentTimeIndex = nil
        let timeValues = times.map { NSValue(CMTime: CMTime(seconds: $0, preferredTimescale: 1000)) }
        timeObserver = player.addBoundaryTimeObserverForTimes(timeValues, queue: nil) { [weak self] in
            self?.handleTimeBoundaryReached()
        }
    }

    private func handleTimeBoundaryReached() {
        guard let currentItem = player.currentItem, let times = playingItemBoundaries[currentItem] else {
            return
        }

        let time = player.currentTime().seconds

        var currentIndex = currentTimeIndex.map { $0 + 1 } ?? 0
        while currentIndex < times.count && times[currentIndex] < time {
            currentIndex += 1
        }

        let finalIndex = max(currentIndex - 1, 0)
        currentTimeIndex = finalIndex
        notifyCurrentTimeChanged(currentItem, timeIndex: finalIndex)
    }

    private func removeCurrentItemObserver() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        unobserve(self.player, keyPath: "currentItem")
    }

    private func stopPlayback() {
        removeCurrentItemObserver()
        timeObserver = nil
        playingItems.removeAll(keepCapacity: true)
        playingItemBoundaries.removeAll(keepCapacity: true)
        player.removeAllItems()
        notifyPlaybackEnded()
    }

    private func notifyPlaybackEnded() {
        onPlaybackEnded?()
    }

    private func notifyPlayerItemChangedTo(newItem: AVPlayerItem?) {
        onPlayerItemChangedTo?(newItem)
    }

    private func notifyCurrentTimeChanged(newItem: AVPlayerItem, timeIndex: Int) {
        onPlaybackStartingTimeFrame?(item: newItem, timeIndex: timeIndex)
    }
}
