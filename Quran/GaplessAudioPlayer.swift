//
//  GaplessAudioPlayer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/16/16.
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
import Foundation
import MediaPlayer
import QueuePlayer
import UIKit

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

        timingRetriever.retrieveTiming(for: qari, suras: items.map { $0.sura })
            .then(on: .main) { timings -> Void in
                var mutableTimings = timings
                if let timeArray = mutableTimings[startAyah.sura] {
                    mutableTimings[startAyah.sura] = Array(timeArray.dropFirst(startAyah.ayah - 1))
                }

                var times: [AVPlayerItem: [Double]] = [:]
                var ayahs: [AVPlayerItem: [AyahNumber]] = [:]
                for item in items {
                    var array = unwrap(mutableTimings[item.sura])
                    if array.last?.ayah == AyahNumber(sura: item.sura, ayah: 999) {
                        array = Array(array.dropLast())
                    }
                    times[item] = array.enumerated().map { $0 == 0 && $1.ayah.ayah == 1 ? 0 : $1.seconds }
                    ayahs[item] = array.map { $0.ayah }
                }
                self.ayahsDictionary = ayahs

                let startSuraTimes = unwrap(mutableTimings[startAyah.sura])
                let startTime = startAyah.ayah == 1 ? 0 : startSuraTimes[0].seconds

                self.player.onPlaybackEnded = self.onPlaybackEnded()
                self.player.onPlaybackRateChanged = self.onPlaybackRateChanged()

                self.player.onPlaybackStartingTimeFrame = { [weak self] (item: AVPlayerItem, timeIndex: Int) in
                    guard let item = item as? GaplessPlayerItem, let ayahs = self?.ayahsDictionary[item] else { return }
                    self?.delegate?.playingAyah(ayahs[timeIndex])
                }
                self.player.play(startTimeInSeconds: startTime, items: items, info: info, boundaries: times)
            }.cauterize(tag: "QariTimingRetriever.retrieveTiming(for:suras:)")
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
                artwork: UIImage(named: qari.imageName)
                    .flatMap { MPMediaItemArtwork(image: $0) })
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
            let fileName = sura.as3DigitString()
            let localURL = qari.localFolder().appendingPathComponent(fileName).appendingPathExtension(Files.audioExtension)
            files.append(localURL, sura)
        }
        return files
    }
}
