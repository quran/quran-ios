//
//  QueuePlayer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/22/16.
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
import MediaPlayer
import VFoundation

open class QueuePlayer: NSObject {
    private let player: AVQueuePlayerFacade = AVQueuePlayerFacade()

    private var playingItemBoundaries: [AVPlayerItem: [Double]] = [:]
    private var playingItems: [AVPlayerItem] = []
    private var playingItemsInfo: [PlayerItemInfo] = []
    private var playingLastTimeIndex: Int?

    public var verseRuns: Runs = .one
    private var playing: Playing?

    public var listRuns: Runs = .one
    private var listPlays: Int = 0

    open var onPlaybackEnded: (() -> Void)?
    open var onPlayerItemChangedTo: ((AVPlayerItem?) -> Void)?
    open var onPlaybackStartingTimeFrame: ((_ item: AVPlayerItem, _ timeIndex: Int) -> Void)?
    open var onPlaybackRateChanged: ((_ playing: Bool) -> Void)?

    private var startTime: Double {
        return unwrap(playingItemBoundaries[playingItems[0]])[0]
    }

    public override init() {
        super.init()
        if #available(iOS 10.0, *) {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        } else {
            try? AVAudioSession.sharedInstance().setCategoryiO9Compatible(.playback)
        }
        player.actionAtItemEnd = .advance

        setUpRemoteControlEvents()
    }

    open func play(items: [AVPlayerItem],
                   info: [PlayerItemInfo],
                   boundaries: [AVPlayerItem: [Double]],
                   lastTimeIndex: Int? = nil) {

        guard items.count == info.count && items.count == boundaries.count else {
            VFoundation.fatalError("Misconfigured QueuePlayer. items, info and boundaries should have the same size.")
        }

        listPlays = 0
        playing = nil
        playingItems = items
        playingItemsInfo = info
        playingItemBoundaries = boundaries
        playingLastTimeIndex = lastTimeIndex

        player.addRateObserver { [weak self] newValue in
            self?.updatePlayNowInfo()
            if let newValue = newValue {
                self?.onPlaybackRateChanged?(newValue != 0)
            }
        }
        player.addInterruptionObserver { [weak self] shouldResume in
            if shouldResume {
                self?.player.play()
            }
        }
        setCommandsEnabled(true)

        play(from: startTime, itemIndex: 0)
    }

    open func pause() {
        player.pause()
    }

    open func resume() {
        player.play()
    }

    open func stop() {
        stopPlayback()
    }

    open func oneStepForward() {
        playing = nil
        guard let currentItem = player.currentItem,
            let boundaries = playingItemBoundaries[currentItem] else {
            return
        }

        let timeIndex = findCurrentTimeIndexUsingBinarySearch()

        if timeIndex + 1 < boundaries.count {
            // play next time range
            let newTimeIndex = timeIndex + 1

            guard !hasReachedEnd(timeIndex: newTimeIndex, currentItem: currentItem) else {
                stopPlayback()
                return
            }
            player.seek(to: boundaries[newTimeIndex])
        } else {
            // play next item
            guard playingItems.last != player.currentItem else {
                stopPlayback()
                return
            }
            playNextAudioItem()
        }
        recalculateAndNotifyCurrentTimeChange()
    }

    private func playNextAudioItem() {
        let oldRate = player.rate

        startFromBegining()
        player.advanceToNextItem()
        player.play()

        player.rate = oldRate
    }

    open func oneStepBackward() {
        playing = nil
        guard let currentItem = player.currentItem,
              let boundaries = playingItemBoundaries[currentItem] else {
                return
        }

        let timeIndex = findCurrentTimeIndexUsingBinarySearch()
        if timeIndex - 1 >= 0 {
            // play previous time range
            let newTimeIndex = timeIndex - 1
            player.seek(to: boundaries[newTimeIndex])
            let oldRate = player.rate
            player.play()
            player.rate = oldRate
        } else {
            // play previous item
            let currentItemIndex = playingItems.index(of: currentItem) ?? 0
            let previousItemIndex = currentItemIndex - 1
            guard previousItemIndex >= 0 else {
                stopPlayback()
                return
            }
            let previousItem = playingItems[previousItemIndex]
            guard let previousBoundaries = playingItemBoundaries[previousItem] else {
                return
            }

            let oldRate = player.rate
            play(from: previousBoundaries[previousBoundaries.count - 1], itemIndex: previousItemIndex)
            player.rate = oldRate
        }
        recalculateAndNotifyCurrentTimeChange()
    }

    private func play(from timeInSeconds: Double, itemIndex: Int) {
        startFromBegining()
        removeCurrentItemObservers()
        player.removeAllItems()
        playingItems.suffix(from: itemIndex).forEach { player.insert($0, after: nil) }
        player.seek(to: timeInSeconds)
        player.play()
        addCurrentItemObserver()
    }

    fileprivate func startFromBegining() {
        player.pause()
        player.seek(to: 0)
    }

    fileprivate func addCurrentItemObserver() {
        player.addCurrentItemObserver { [weak self] newItem in
            self?.currentItemChanged(newItem)
        }
    }

    private func stopIfCompleted() {
        // last item finished playing
        if listRunsCompleted() {
            stopPlayback()
        } else {
            listPlays.increment()
            play(from: self.startTime, itemIndex: 0)
        }
    }

    private func currentItemChanged(_ newValue: AVPlayerItem?) {
        guard let newValue = newValue else { return }

        player.addCurrentItemReachedEndObserver(newValue) { [weak self] in
            guard let `self` = self else { return }
            // determine to repeat or stop playback
            if self.playingItems.last == self.player.currentItem {
                if self.verseRunsCompleted() {
                    self.stopIfCompleted()
                } else {
                    self.onTimeChange()
                }
            }
        }
        player.addDurationObserver(to: newValue) { [weak self] in
            self?.updatePlayNowInfo()
        }
        startBoundaryObserver(newValue)
        notifyPlayerItemChangedTo(newValue)
        onTimeChange()
        updatePlayNowInfo()
    }

    private func hasReachedEnd(timeIndex: Int, currentItem: AVPlayerItem) -> Bool {
        guard let playingLastTimeIndex = playingLastTimeIndex else {
            return false
        }
        return currentItem == playingItems.last && timeIndex > playingLastTimeIndex
    }

    private func startBoundaryObserver(_ newItem: AVPlayerItem) {
        guard var times = playingItemBoundaries[newItem] else { return }
        // we don't get notified by boundary change of 0
        if times[0] == 0 {
            times[0] = 0.01
        }
        player.addBoundaryTimeObserver(for: times) { [weak self] in
            self?.onTimeChange()
        }
    }

    private func onTimeChange() {
        guard let currentItem = player.currentItem else { return }
        let timeIndex = findCurrentTimeIndexUsingBinarySearch()
        let ignore =
            playing?.item == currentItem &&
            timeIndex == (playing?.time ?? -1) &&
            (playing?.recentlyUpdated ?? false)
        if !ignore {
            if let playing = self.playing, !verseRunsCompleted() {
                self.playing?.increment()
                replay(item: playing.item, timeIndex: playing.time)
            } else {
                self.playing = Playing(item: currentItem, time: timeIndex)
                guard !hasReachedEnd(timeIndex: timeIndex, currentItem: currentItem) else {
                    stopIfCompleted()
                    return
                }
            }
        }
        // notify only on first play
        if self.playing?.plays == 0 {
            self.notifyCurrentTimeChanged(currentItem, timeIndex: timeIndex)
        }
    }

    private func recalculateAndNotifyCurrentTimeChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let currentItem = self.player.currentItem else { return }
            let timeIndex = self.findCurrentTimeIndexUsingBinarySearch()
            self.notifyCurrentTimeChanged(currentItem, timeIndex: timeIndex)
        }
    }

    private func verseRunsCompleted() -> Bool {
        return playsCompleted(playing?.plays, runs: verseRuns)
    }

    private func listRunsCompleted() -> Bool {
        return playsCompleted(listPlays, runs: listRuns)
    }

    private func playsCompleted(_ plays: Int?, runs: Runs) -> Bool {
        if runs == .indefinite {
            return false
        }
        if let plays = plays {
            return plays  + 1 >= runs.maxRuns
        }
        return false
    }

    private func replay(item: AVPlayerItem, timeIndex: Int) {
        guard let itemIndex = playingItems.index(of: item),
              let times = playingItemBoundaries[item] else {
            return
        }
        play(from: times[timeIndex], itemIndex: itemIndex)
    }

    private func removeCurrentItemObservers() {
        player.removeCurrentItemReachedEndObserver()
        player.removeDurationObserver()
        player.removeCurrentItemObserver()
        player.removeBoundaryTimeObserver()
    }

    private func stopPlayback() {
        setCommandsEnabled(false)
        removeCurrentItemObservers()
        player.removeInterruptionObserver()
        player.removeRateObserver()
        playingItems.removeAll(keepingCapacity: true)
        playingItemBoundaries.removeAll(keepingCapacity: true)
        player.removeAllItems()
        playing = nil
        updatePlayNowInfo()
        notifyPlaybackEnded()
    }

    fileprivate func notifyPlaybackEnded() {
        onPlaybackEnded?()
    }

    fileprivate func notifyPlayerItemChangedTo(_ newItem: AVPlayerItem?) {
        onPlayerItemChangedTo?(newItem)
    }

    fileprivate func notifyCurrentTimeChanged(_ newItem: AVPlayerItem, timeIndex: Int) {
        onPlaybackStartingTimeFrame?(newItem, timeIndex)
    }
}

extension QueuePlayer {
    private func findCurrentTimeIndexUsingBinarySearch() -> Int {
        guard let currentItem = player.currentItem,
            let times = playingItemBoundaries[currentItem] else {
                VFoundation.fatalError("Cannot find current time when there are no audio playing.")
        }
        let time = player.currentTime.seconds

        if times.isEmpty {
            guard var index = playingItems.index(of: currentItem) else {
                VFoundation.fatalError("Couldn't find current item in the play list.")
            }
            while index > 0 {
                guard let times = playingItemBoundaries[playingItems[index - 1]] else {
                    VFoundation.fatalError("Cannot find previous times in the array.")
                }
                if !times.isEmpty {
                    return times.count - 1
                }
                index -= 1
            }
            VFoundation.fatalError("First item should have a monitor location")
        }

        // search through the array
        return binarySearch(times, value: time + 0.2)
    }

    private func binarySearch(_ values: [Double], value: Double) -> Int {
        let index = values.binarySearch(value)
        guard index < values.count else {
            return values.count - 1
        }
        if value < values[index] && index > 0 {
            return index - 1
        } else {
            return index
        }
    }
}

extension QueuePlayer {
    private func setUpRemoteControlEvents() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget (handler: { [weak self] _ in
            self?.resume()
            return .success
        })
        center.pauseCommand.addTarget (handler: { [weak self] _ in
            self?.pause()
            return .success
        })
        center.togglePlayPauseCommand.addTarget (handler: { [weak self] _ in
            if self?.player.rate == 0 {
                self?.resume()
            } else {
                self?.pause()
            }
            return .success
        })
        center.nextTrackCommand.addTarget (handler: { [weak self] _ in
            self?.oneStepForward()
            return .success
        })
        center.previousTrackCommand.addTarget (handler: { [weak self] _ in
            self?.oneStepBackward()
            return .success
        })
        setCommandsEnabled(false)

        // disabled unused command
        if #available(iOS 9.1, *) {
            [center.seekForwardCommand, center.seekBackwardCommand, center.skipForwardCommand,
             center.skipBackwardCommand, center.ratingCommand, center.changePlaybackRateCommand,
             center.likeCommand, center.dislikeCommand, center.bookmarkCommand, center.changePlaybackPositionCommand].forEach { $0.isEnabled = false }
        }
    }

    private func setCommandsEnabled(_ enabled: Bool) {
        let center = MPRemoteCommandCenter.shared()
        [center.playCommand, center.pauseCommand, center.togglePlayPauseCommand,
         center.nextTrackCommand, center.previousTrackCommand].forEach { $0.isEnabled = enabled }
    }
}

extension QueuePlayer {
    private func updatePlayNowInfo() {
        let center = MPNowPlayingInfoCenter.default()

        guard let currentItem = player.currentItem, let index = playingItems.index(of: currentItem) else {
            if playingItems.isEmpty {
                center.nowPlayingInfo = nil
            }
            return
        }

        let itemInfo = playingItemsInfo[index]

        var info: [String: AnyObject] = [:]
        info[MPNowPlayingInfoPropertyPlaybackQueueCount] = playingItems.count as AnyObject
        if let index = playingItems.index(of: currentItem) {
            info[MPNowPlayingInfoPropertyPlaybackQueueIndex] = index as AnyObject
        }
        info[MPNowPlayingInfoPropertyPlaybackRate] = player.rate as AnyObject
        info[MPMediaItemPropertyPlaybackDuration] = currentItem.duration.seconds as AnyObject
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentItem.currentTime().seconds as AnyObject
        info[MPMediaItemPropertyTitle] = itemInfo.title as AnyObject
        info[MPMediaItemPropertyArtist] = itemInfo.artist as AnyObject
        info[MPMediaItemPropertyArtwork] = itemInfo.artwork
        center.nowPlayingInfo = info
    }
}
