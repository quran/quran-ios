//
//  GaplessAudioPlayer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/16/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import AVFoundation

private class GaplessPlayerItem: AVPlayerItem {
    let sura: Int
    init(URL: NSURL, sura: Int) {
        self.sura = sura
        super.init(asset: AVAsset(URL: URL), automaticallyLoadedAssetKeys: nil)
    }

    private override var description: String {
        return super.description + " sura: \(sura)"
    }
}

class GaplessAudioPlayer: NSObject, DefaultAudioPlayer {

    weak var delegate: AudioPlayerDelegate?

    var inAudioSession: Bool = false

    let player = AVQueuePlayer()

    var playingItems: [AVPlayerItem] = []

    var observingObject: NSObject {
        return self
    }

    let timingRetriever: QariTimingRetriever

    var timings: [AyahNumber: AyahTiming] = [:]

    var playingAyah: AyahNumber? =  nil {
        didSet {
            if let playingAyah = playingAyah where playingAyah != oldValue {
                delegate?.playingAyah(playingAyah)
            }
            print(playingAyah)
        }
    }

    var qari: Qari?

    var timeObserver: AnyObject? {
        didSet {
            if let oldValue = oldValue {
                player.removeTimeObserver(oldValue)
            }
        }
    }

    init(timingRetriever: QariTimingRetriever) {
        self.timingRetriever = timingRetriever
        super.init()
        let _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord,
                                                                 withOptions: [.DefaultToSpeaker, .AllowBluetooth])
        player.actionAtItemEnd = .Advance
    }

    func prepareToPlayForFirstTime(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber, playBlock: () -> Void) {
        self.qari = qari
        timingRetriever.retrieveTimingForQari(qari, startAyah: startAyah) { [weak self] timings in
            timings.forEach { self?.timings[$0] = $1 }
            guard let timing = timings[startAyah] else {
                fatalError("SQLite didn't retrieve timing for the start ayah.")
            }
            self?.seekTo(startAyah.ayah == 1 ? 0 : timing.timeInSeconds)
            self?.playingAyah = startAyah
            self?.startPeriodTimeObserver()
            playBlock()
        }
    }

    func playerItemsForQari(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [AVPlayerItem] {
        return filesToPlay(qari: qari, startAyah: startAyah, endAyah: endAyah).map { GaplessPlayerItem(URL: $0, sura: $1) }
    }

    func onPlayingStopped() {
        // reset
        timings = [:]
        timeObserver = nil
        qari = nil
        playingAyah = nil
    }

    func goForward() {
        goToAyah(playingAyah?.nextAyah()) { _ in  playNextAudio(starting: 0) }
    }

    func goBackward() {
        goToAyah(playingAyah?.previousAyah()) { ayah in
            if let time = timings[ayah] {
                playPreviousAudio(starting: time.timeInSeconds)
            }
        }
    }

    private func goToAyah(ayah: AyahNumber?, @noescape playAnotherSuraBlock: AyahNumber -> Void) {
        guard let otherAyah = ayah else {
            stop() // stop, if the first or last ayah
            return
        }

        if otherAyah.sura == playingAyah?.sura {
            if let time = timings[otherAyah] {
                playingAyah = otherAyah
                seekTo(otherAyah.ayah == 1 ? 0 : time.timeInSeconds)
            }
        } else {
            playingAyah = otherAyah
            startPeriodTimeObserver()
            playAnotherSuraBlock(otherAyah)
        }
    }

    func onPlayerItemChangedTo(newItem: AVPlayerItem) {
        if let newItem = newItem as? GaplessPlayerItem where newItem.sura != playingAyah?.sura {
            playingAyah = AyahNumber(sura: newItem.sura, ayah: 1)
            startPeriodTimeObserver()
        }
    }
}

extension GaplessAudioPlayer {

    private func startPeriodTimeObserver() {
        guard
            let qari = qari,
            let playingAyah = playingAyah,
            let nextAyah = playingAyah.nextAyah() else {
                return
        }
        print("startPeriodTimeObserver")

        if timings[nextAyah] != nil {
            var nextAyah: AyahNumber? = nextAyah
            var timingsArray: [AyahTiming] = []
            while let next = nextAyah where next.sura == playingAyah.sura {
                if let timing = timings[next] {
                    timingsArray.append(timing)
                }
                nextAyah = next.nextAyah()
            }
            print("use cached data")
            addTimeObserverForTimings(timingsArray)
        } else {
            print("retrieveTimingForQari")
            timingRetriever.retrieveTimingForQari(qari, startAyah: playingAyah, onCompletion: { [weak self] (timings) in
                timings.forEach { self?.timings[$0] = $1 }
                self?.addTimeObserverForTimings(timings.map { $1 })
            })
        }
    }

    private func addTimeObserverForTimings(timings: [AyahTiming]) {
        guard !timings.isEmpty else { return }

        let times = timings.map { NSValue(CMTime: CMTime(seconds: $0.timeInSeconds, preferredTimescale: 1000)) }
        timeObserver = player.addBoundaryTimeObserverForTimes(times, queue: nil) { [weak self] in
            self?.updatePlayingAyah()
        }
    }

    private func updatePlayingAyah() {
        guard let playingAyah = playingAyah,
            let currenItem = player.currentItem as? GaplessPlayerItem,
            let nextAyah = playingAyah.nextAyah() where playingAyah.sura == currenItem.sura else {
            return
        }

        let time = player.currentTime()

        let timInMilliSeconds = Int(time.seconds * 1000)
        var loopAyah: AyahNumber? = nextAyah

        var currentAyah = playingAyah
        while let next = loopAyah, let time = timings[next] where next.sura == playingAyah.sura {
            if timInMilliSeconds < time.time {
                break
            }
            currentAyah = next
            loopAyah = next.nextAyah()
        }
        self.playingAyah = currentAyah
    }

    private func filesToPlay(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [(NSURL, Int)] {

        guard case AudioType.Gapless = qari.audioType else {
            fatalError("Unsupported qari type gapped. Only gapless qaris can be played here.")
        }

        // loop over the files
        var files = [(NSURL, Int)]()
        for sura in startAyah.sura...endAyah.sura {
            let fileName = String(format: "%03d", sura)
            let localURL = qari.localFolder().URLByAppendingPathComponent(fileName).URLByAppendingPathExtension(Files.AudioExtension)
            files.append(localURL, sura)
        }
        return files
    }
}
