//
//  AVQueuePlayerFacade.swift
//  Quran
//
//  Created by Mohamed Afifi on 03/31/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
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
import VFoundation

class AVQueuePlayerFacade: NSObject {
    private let player: AVQueuePlayer = AVQueuePlayer()
    private var timeObserver: Any? {
        didSet {
            if let oldValue = oldValue {
                player.removeTimeObserver(oldValue)
            }
        }
    }
    private var currentItemObservation: NSKeyValueObservation? {
        didSet { oldValue?.invalidate() }
    }
    private var durationObservation: NSKeyValueObservation? {
        didSet { oldValue?.invalidate() }
    }
    private var rateObservation: NSKeyValueObservation? {
        didSet { oldValue?.invalidate() }
    }

    private var interruptionObserver: ((Bool) -> Void)? {
        didSet {
            if interruptionObserver == nil {
                NotificationCenter.default.removeObserver(self, name: .AVAudioSessionInterruption, object: nil)
            }
        }
    }

    private var currentItemReachedEndObserver: (() -> Void)? {
        didSet {
            if currentItemReachedEndObserver == nil {
                NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
            }
        }
    }

    var actionAtItemEnd: AVPlayerActionAtItemEnd {
        get { return player.actionAtItemEnd }
        set { player.actionAtItemEnd = newValue }
    }
    var rate: Float {
        get { return player.rate }
        set { player.rate = newValue }
    }

    var currentItem: AVPlayerItem? { return player.currentItem }
    var currentTime: CMTime { return player.currentTime() }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func insert(_ item: AVPlayerItem, after afterItem: AVPlayerItem?) {
        player.insert(item, after: afterItem)
    }

    func removeAllItems() {
        player.removeAllItems()
    }

    func play() {
        player.play()
         // There is a bug with using rate of 1.0 where the currentItem sometimes not updated immediately
        player.rate = 1.001
    }

    func pause() {
        player.pause()
    }

    func advanceToNextItem() {
        player.advanceToNextItem()
    }

    func seek(to timeInSeconds: Double) {
        let time = CMTime(seconds: timeInSeconds, preferredTimescale: 1_000)
        player.seek(to: time)
    }

    func addBoundaryTimeObserver(for times: [Double], queue: DispatchQueue? = nil, using observer: @escaping () -> Void) {
        let timeValues = times.map { NSValue(time: CMTime(seconds: $0, preferredTimescale: 1_000)) }
        timeObserver = player.addBoundaryTimeObserver(forTimes: timeValues, queue: queue, using: {
            observer()
        })
    }

    func removeBoundaryTimeObserver() {
        timeObserver = nil
    }

    func addDurationObserver(to item: AVPlayerItem, observer: @escaping () -> Void) {
        durationObservation = item.observe(\AVPlayerItem.duration, options: [.initial, .new]) { (_, _) in
            observer()
        }
    }

    func removeDurationObserver() {
        durationObservation = nil
    }

    func addRateObserver(_ observer: @escaping (Float?) -> Void) {
        rateObservation = player.observe(\AVQueuePlayer.rate, options: [.initial, .new]) { (_, change) in
           observer(change.newValue)
        }
    }

    func removeRateObserver() {
        rateObservation = nil
    }

    func addCurrentItemObserver(_ observer: @escaping (AVPlayerItem?) -> Void) {
        currentItemObservation = player.observe(\AVQueuePlayer.currentItem, options: [.initial, .new]) { (_, change) in
            observer(change.newValue.flatMap { $0 })
        }
    }

    func removeCurrentItemObserver() {
        currentItemObservation = nil
    }

    func addInterruptionObserver(_ observer: @escaping (Bool) -> Void) {
        interruptionObserver = observer
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onAudioInterruptionStateChanged(_:)),
                                               name: NSNotification.Name.AVAudioSessionInterruption,
                                               object: nil)
    }

    @objc
    private func onAudioInterruptionStateChanged(_ notification: Notification) {
        guard let info = notification.userInfo, notification.name == .AVAudioSessionInterruption else {
            return
        }

        guard let rawType = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSessionInterruptionType(rawValue: rawType) else {
                return
        }

        switch type {
        case .began: break
        case .ended:
            if let rawOptions = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSessionInterruptionOptions(rawValue: rawOptions)
                let shouldResume = options.contains(.shouldResume)
                interruptionObserver?(shouldResume)
            }
        }
    }

    func removeInterruptionObserver() {
        interruptionObserver = nil
    }

    func addCurrentItemReachedEndObserver(_ item: AVPlayerItem, _ observer: @escaping () -> Void) {
        currentItemReachedEndObserver = observer
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onCurrentItemReachedEnd),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: item)
    }

    @objc
    private func onCurrentItemReachedEnd() {
        currentItemReachedEndObserver?()
    }

    func removeCurrentItemReachedEndObserver() {
        currentItemReachedEndObserver = nil
    }
}
