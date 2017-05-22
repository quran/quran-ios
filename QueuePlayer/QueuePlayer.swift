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
import AVFoundation
import KVOController
import MediaPlayer
import VFoundation

public struct PlayerItemInfo {
    public let title: String
    public let artist: String
    public let artwork: MPMediaItemArtwork?
    public init(title: String, artist: String, artwork: MPMediaItemArtwork?) {
        self.title = title
        self.artist = artist
        self.artwork = artwork
    }
}

private class _Observer: NSObject {
}

open class QueuePlayer: NSObject {

    let player: AVQueuePlayer = AVQueuePlayer()

    fileprivate (set) var playingItemBoundaries: [AVPlayerItem: [Double]] = [:]
    var playingItems: [AVPlayerItem] = []
    var playingItemsInfo: [PlayerItemInfo] = []

    open var onPlaybackEnded: (() -> Void)?
    open var onPlayerItemChangedTo: ((AVPlayerItem?) -> Void)?
    open var onPlaybackStartingTimeFrame: ((_ item: AVPlayerItem, _ timeIndex: Int) -> Void)?
    open var onPlaybackRateChanged: ((_ playing: Bool) -> Void)?

    fileprivate var timeObserver: AnyObject? {
        didSet {
            if let oldValue = oldValue {
                player.removeTimeObserver(oldValue)
            }
        }
    }

    fileprivate var durationObserver: _Observer? {
        didSet {
            oldValue?.kvoController.unobserveAll()
        }
    }

    fileprivate var rateObserver: _Observer? {
        didSet {
            oldValue?.kvoController.unobserveAll()
        }
    }

    public override init() {
        super.init()

        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [.defaultToSpeaker, .allowBluetooth])
        player.actionAtItemEnd = .advance

        setUpRemoteControlEvents()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate func setUpRemoteControlEvents() {
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
            self?.onStepForward()
            return .success
        })
        center.previousTrackCommand.addTarget (handler: { [weak self] _ in
            self?.onStepBackward()
            return .success
        })
        setCommandsEnabled(false)

        // disabled unused command
        if #available(iOS 9.1, *) {
            [center.seekForwardCommand, center.seekBackwardCommand, center.skipForwardCommand,
             center.skipBackwardCommand, center.ratingCommand, center.changePlaybackRateCommand,
             center.likeCommand, center.dislikeCommand, center.bookmarkCommand, center.changePlaybackPositionCommand].forEach { $0.isEnabled = false }
        } else {
            // Fallback on earlier versions
        }
    }

    func setCommandsEnabled(_ enabled: Bool) {
        let center = MPRemoteCommandCenter.shared()
        [center.playCommand, center.pauseCommand, center.togglePlayPauseCommand,
            center.nextTrackCommand, center.previousTrackCommand].forEach { $0.isEnabled = enabled }
    }

    open func play(startTimeInSeconds: Double = 0,
                   items: [AVPlayerItem],
                   info: [PlayerItemInfo],
                   boundaries: [AVPlayerItem: [Double]]) {

        guard items.count == info.count && items.count == boundaries.count else {
            VFoundation.fatalError("Misconfigured QueuePlayer. items, info and boundaries should have the same size.")
        }

        playingItems = items
        playingItemsInfo = info
        self.playingItemBoundaries = boundaries

        rateObserver = _Observer()
        rateObserver?.kvoController.observe(player, keyPath: #keyPath(AVQueuePlayer.rate),
                                            options: [.initial, .new], block: { [weak self] (_, _, change) in
            self?.updatePlayNowInfo()
            if let newValue = change[NSKeyValueChangeKey.newKey.rawValue] as? Int {
                self?.onPlaybackRateChanged?(newValue != 0)
            }
        })

        // enqueue new items
        player.removeAllItems()
        items.forEach { self.player.insert($0, after: nil) }

        seekTo(startTimeInSeconds)
        player.play()
        addCurrentItemObserver()
        _currentItemChanged(player.currentItem)
        setCommandsEnabled(true)

        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(onAudioInterruptionStateChanged(_:)),
                                                         name: NSNotification.Name.AVAudioSessionInterruption,
                                                         object: nil)
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

    open func onStepForward() {
        guard let currentItem = player.currentItem,
            let boundaries = playingItemBoundaries[currentItem] else {
            return
        }

        let currentIndex = findCurrentTimeIndexUsingBinarySearch()

        if currentIndex + 1 < boundaries.count {
            let newTimeIndex = currentIndex + 1
            seekTo(boundaries[newTimeIndex])
        } else {
            playNextAudio(starting: 0)
        }
        recalculateAndNotifyCurrentTimeChange()
    }

    open func onStepBackward() {
        guard let currentItem = player.currentItem,
            let boundaries = playingItemBoundaries[currentItem] else {
                return
        }

        let currentIndex = findCurrentTimeIndexUsingBinarySearch()

        if currentIndex - 1 >= 0 {
            let newTimeIndex = currentIndex - 1
            seekTo(boundaries[newTimeIndex])
        } else {

            let index = playingItems.index(of: currentItem) ?? 0
            guard index > 0 else {
                stop()
                return
            }
            guard let previousBoundaries = playingItemBoundaries[playingItems[index - 1]] else { return }

            let newTimeIndex = previousBoundaries.count - 1
            playPreviousAudio(starting: previousBoundaries[newTimeIndex])
        }
        recalculateAndNotifyCurrentTimeChange()
    }

    fileprivate func playNextAudio(starting timeInSeconds: Double) {
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

    fileprivate func playPreviousAudio(starting timeInSeconds: Double) {
        guard let currentItem = player.currentItem,
            var index = playingItems.index(of: currentItem) else {
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
            player.insert(playingItems[i], after: nil)
        }
        addCurrentItemObserver()
        seekTo(timeInSeconds)
        _currentItemChanged(player.currentItem)
        player.play()
        player.rate = oldRate
    }

    fileprivate func startFromBegining() {
        player.pause()
        seekTo(0)
    }

    fileprivate func seekTo(_ timeInSeconds: Double) {
        let time = CMTime(seconds: timeInSeconds, preferredTimescale: 1_000)
        player.seek(to: time)
    }

    fileprivate func addCurrentItemObserver() {
        kvoController.observe(player, keyPath: #keyPath(AVQueuePlayer.currentItem), options: .new,
                              block: { [weak self] (_: Any, _: Any, change: [String: Any]) in
            self?._currentItemChanged(change[NSKeyValueChangeKey.newKey.rawValue] as? AVPlayerItem)
        })
    }

    fileprivate func _currentItemChanged(_ newValue: AVPlayerItem?) {
        guard let newValue = newValue else { return }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onCurrentItemReachedEnd),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: newValue)

        durationObserver = _Observer()
        durationObserver?.kvoController.observe(newValue, keyPath: #keyPath(AVPlayerItem.duration),
                                                options: [.initial, .new], block: { [weak self] (_, _, _) in
            self?.updatePlayNowInfo()
        })

        startBoundaryObserver(newValue)
        notifyPlayerItemChangedTo(newValue)
        recalculateAndNotifyCurrentTimeChange()
        updatePlayNowInfo()
    }

    func onCurrentItemReachedEnd() {
        // determine to repeat or start next one

        if playingItems.last == player.currentItem {
            // last item finished playing
            stop()
        }
    }

    fileprivate func updatePlayNowInfo() {
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

    fileprivate func startBoundaryObserver(_ newItem: AVPlayerItem) {
        guard let times = playingItemBoundaries[newItem] else { return }

        let timeValues = times.map { NSValue(time: CMTime(seconds: $0, preferredTimescale: 1_000)) }
        timeObserver = player.addBoundaryTimeObserver(forTimes: timeValues, queue: nil) { [weak self] in
            self?.onTimeBoundaryReached()
        } as AnyObject
    }

    fileprivate func onTimeBoundaryReached() {
        recalculateAndNotifyCurrentTimeChange()
    }

    fileprivate func recalculateAndNotifyCurrentTimeChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let currentItem = self.player.currentItem else { return }
            let timeIndex = self.findCurrentTimeIndexUsingBinarySearch()
            self.notifyCurrentTimeChanged(currentItem, timeIndex: timeIndex)
        }
    }

    fileprivate func removeCurrentItemObserver() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        kvoController.unobserve(self.player, keyPath: #keyPath(AVQueuePlayer.currentItem))
    }

    fileprivate func removeInterruptionNotification() {
        NotificationCenter.default.removeObserver(self, name: .AVAudioSessionInterruption, object: nil)
    }

    fileprivate func stopPlayback() {
        setCommandsEnabled(false)
        removeInterruptionNotification()
        removeCurrentItemObserver()
        rateObserver = nil
        timeObserver = nil
        durationObserver = nil
        playingItems.removeAll(keepingCapacity: true)
        playingItemBoundaries.removeAll(keepingCapacity: true)
        player.removeAllItems()
        updatePlayNowInfo()
        notifyPlaybackEnded()
    }

    func onAudioInterruptionStateChanged(_ notification: Notification) {
        guard let info = (notification as NSNotification).userInfo, notification.name == .AVAudioSessionInterruption else {
            return
        }

        guard let rawType = info[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSessionInterruptionType(rawValue: rawType) else {
            return
        }

        switch type {
        case .began: break
        case .ended:
            if let rawOptions = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSessionInterruptionOptions(rawValue: rawOptions)
                if options.contains(.shouldResume) {
                    player.play()
                }
            }
        }
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

    fileprivate func findCurrentTimeIndexUsingBinarySearch() -> Int {
        guard let currentItem = player.currentItem,
            let times = playingItemBoundaries[currentItem] else {
            VFoundation.fatalError("Cannot find current time when there are no audio playing.")
        }
        let time = player.currentTime().seconds

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

    fileprivate func binarySearch(_ values: [Double], value: Double) -> Int {
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
