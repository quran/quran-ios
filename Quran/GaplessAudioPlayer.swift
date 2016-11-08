//
//  GaplessAudioPlayer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/16/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import MediaPlayer

private class GaplessPlayerItem: AVPlayerItem {
    let sura: Int
    init(URL: URL, sura: Int) {
        self.sura = sura
        super.init(asset: AVAsset(url: URL), automaticallyLoadedAssetKeys: nil)
    }

    fileprivate override var description: String {
        return super.description + " sura: \(sura)"
    }
}

class GaplessAudioPlayer: DefaultAudioPlayer {

    weak var delegate: AudioPlayerDelegate?

    let player = QueuePlayer()

    let timingRetriever: QariTimingRetriever

    fileprivate var ayahsDictionary: [AVPlayerItem: [AyahNumber]] = [:]

    init(timingRetriever: QariTimingRetriever) {
        self.timingRetriever = timingRetriever
    }

    func play(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) {
        let (items, info) = playerItemsForQari(qari, startAyah: startAyah, endAyah: endAyah)

        timingRetriever.retrieveTimingForQari(qari, suras: items.map { $0.sura }) { [weak self] timingsResult in
            guard let timings = timingsResult.value else { return }

            var mutableTimings = timings
            if let timeArray = mutableTimings[startAyah.sura] {
                mutableTimings[startAyah.sura] = Array(timeArray.dropFirst(startAyah.ayah - 1))
            }

            var times: [AVPlayerItem: [Double]] = [:]
            var ayahs: [AVPlayerItem: [AyahNumber]] = [:]
            for item in items {
                var array: [AyahTiming] = cast(mutableTimings[item.sura])
                if array.last?.ayah == AyahNumber(sura: item.sura, ayah: 999) {
                    array = Array(array.dropLast())
                }
                times[item] = array.enumerated().map { $0 == 0 && $1.ayah.ayah == 1 ? 0 : $1.seconds }
                ayahs[item] = array.map { $0.ayah }
            }
            self?.ayahsDictionary = ayahs

            let startSuraTimes: [AyahTiming] = cast(mutableTimings[startAyah.sura])
            let startTime = startAyah.ayah == 1 ? 0 : startSuraTimes[0].seconds

            self?.player.onPlaybackEnded = self?.onPlaybackEnded()
            self?.player.onPlaybackRateChanged = self?.onPlaybackRateChanged()

            self?.player.onPlaybackStartingTimeFrame = { [weak self] (item: AVPlayerItem, timeIndex: Int) in
                guard let item = item as? GaplessPlayerItem, let ayahs = self?.ayahsDictionary[item] else { return }
                self?.delegate?.playingAyah(ayahs[timeIndex])
            }
            self?.player.play(startTimeInSeconds: startTime, items: items, info: info, boundaries: times)
        }
    }
}

extension GaplessAudioPlayer {

    fileprivate func playerItemsForQari(_ qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> ([GaplessPlayerItem], [PlayerItemInfo]) {
        let files = filesToPlay(qari: qari, startAyah: startAyah, endAyah: endAyah)
        let items = files.map { GaplessPlayerItem(URL: $0, sura: $1) }
        let info = files.map {
            PlayerItemInfo(
                title: Quran.nameForSura($1),
                artist: qari.name,
                artwork: qari.imageName.flatMap({UIImage(named: $0)}).flatMap { MPMediaItemArtwork(image: $0) })
        }
        return (items, info)
    }

    fileprivate func filesToPlay(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [(URL, Int)] {

        guard case AudioType.gapless = qari.audioType else {
            fatalError("Unsupported qari type gapped. Only gapless qaris can be played here.")
        }

        // loop over the files
        var files: [(URL, Int)] = []
        for sura in startAyah.sura...endAyah.sura {
            let fileName = String(format: "%03d", sura)
            let localURL = qari.localFolder().appendingPathComponent(fileName).appendingPathExtension(Files.audioExtension)
            files.append(localURL, sura)
        }
        return files
    }
}
