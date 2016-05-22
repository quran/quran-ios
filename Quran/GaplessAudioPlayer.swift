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

class GaplessAudioPlayer: AudioPlayer {

    weak var delegate: AudioPlayerDelegate?

    let player = QueuePlayer()

    let timingRetriever: QariTimingRetriever

    init(timingRetriever: QariTimingRetriever) {
        self.timingRetriever = timingRetriever
    }

    func play(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) {
        let items = playerItemsForQari(qari, startAyah: startAyah, endAyah: endAyah)

        timingRetriever.retrieveTimingForQari(qari, suras: items.map { $0.sura }) { [weak self] timings in

            var mutableTimings = timings
            if let timeArray = mutableTimings[startAyah.sura] {
                mutableTimings[startAyah.sura] = Array(timeArray.dropFirst(startAyah.ayah - 1))
            }

            let times = items.reduce([:]) { (value, item) -> [AVPlayerItem: [Double]] in
                var mutableValue = value
                let array: [AyahTiming] = cast(mutableTimings[item.sura])
                mutableValue[item] = array.enumerate().dropLast().map { $0 == 0 ? 0 : $1.seconds }
                return mutableValue
            }

            let startSuraTimes: [AyahTiming] = cast(mutableTimings[startAyah.sura])
            let startTime = startAyah.ayah == 1 ? 0 : startSuraTimes[0].seconds

            self?.player.onPlaybackEnded = { [weak self] in
                self?.delegate?.onPlaybackEnded()
            }
            self?.player.onPlaybackStartingTimeFrame = { [weak self] (item: AVPlayerItem, timeIndex: Int) in
                guard let item = item as? GaplessPlayerItem else { return }
                let offset = item.sura == startAyah.sura ? startAyah.ayah - 1 : 0
                self?.delegate?.playingAyah(AyahNumber(sura: item.sura, ayah: timeIndex + 1 + offset))
            }

            self?.player.play(startTimeInSeconds: startTime, items: items, playingItemBoundaries: times)
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
        player.onPlaybackEnded = nil
        player.onPlayerItemChangedTo = nil
        player.onPlaybackStartingTimeFrame = nil
    }

    func goForward() {
        player.onStepForward()
    }

    func goBackward() {
        player.onStepBackward()
    }
}

extension GaplessAudioPlayer {

    private func playerItemsForQari(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [GaplessPlayerItem] {
        return filesToPlay(qari: qari, startAyah: startAyah, endAyah: endAyah).map { GaplessPlayerItem(URL: $0, sura: $1) }
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
