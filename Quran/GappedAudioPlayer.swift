//
//  GappedAudioPlayer.swift
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

import Foundation
import AVFoundation
import UIKit
import MediaPlayer
import QueuePlayer

private class GappedPlayerItem: AVPlayerItem {
    let ayah: AyahNumber
    init(URL: URL, ayah: AyahNumber) {
        self.ayah = ayah
        super.init(asset: AVAsset(url: URL), automaticallyLoadedAssetKeys: nil)
    }

    fileprivate override var description: String {
        return super.description + " ayah: \(ayah)"
    }
}

class GappedAudioPlayer: DefaultAudioPlayer {

    let numberFormatter = NumberFormatter()

    weak var delegate: AudioPlayerDelegate?

    let player = QueuePlayer()

    func play(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) {
        let (items, info) = playerItemsForQari(qari, startAyah: startAyah, endAyah: endAyah)

        var times: [AVPlayerItem: [Double]] = [:]
        for item in items {
            times[item] = [0]
        }

        player.onPlaybackEnded = onPlaybackEnded()
        player.onPlaybackRateChanged = onPlaybackRateChanged()

        player.onPlaybackStartingTimeFrame = { [weak self] (item: AVPlayerItem, _) in
            guard let item = item as? GappedPlayerItem else { return }
            self?.delegate?.playingAyah(item.ayah)
        }

        player.play(startTimeInSeconds: 0, items: items, info: info, boundaries: times)
    }
}

extension GappedAudioPlayer {

    fileprivate func playerItemsForQari(_ qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> ([GappedPlayerItem], [PlayerItemInfo]) {
        let files = filesToPlay(qari: qari, startAyah: startAyah, endAyah: endAyah)
        let items = files.map { GappedPlayerItem(URL: $0, ayah: $1) }
        let info: [PlayerItemInfo] = files.map { (_, ayah) in
            return PlayerItemInfo(
                title: ayah.localizedName,
                artist: qari.name,
                artwork: UIImage(named: qari.imageName)
                    .flatMap { MPMediaItemArtwork(image: $0) })
        }
        return (items, info)
    }

    fileprivate func filesToPlay(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [(URL, AyahNumber)] {

        guard case AudioType.gapped = qari.audioType else {
            fatalError("Unsupported qari type gapless. Only gapless qaris can be downloaded here.")
        }

        var files: [(URL, AyahNumber)] = []

        for sura in startAyah.sura...endAyah.sura {

            let startAyahNumber = sura == startAyah.sura ? startAyah.ayah : 1
            let endAyahNumber = sura == endAyah.sura ? endAyah.ayah : Quran.numberOfAyahsForSura(sura)

            // add besm Allah for all except Al-Fatihah and At-Tawbah
            if startAyahNumber == 1 && (sura != 1 && sura != 9) {
                files.append((createRequestInfo(qari: qari, sura: 1, ayah: 1), AyahNumber(sura: sura, ayah: 1)))
            }

            for ayah in startAyahNumber...endAyahNumber {
                files.append((createRequestInfo(qari: qari, sura: sura, ayah: ayah), AyahNumber(sura: sura, ayah: ayah)))
            }
        }
        return files
    }

    fileprivate func createRequestInfo(qari: Qari, sura: Int, ayah: Int) -> URL {
        let fileName = sura.as3DigitString() + ayah.as3DigitString()
        return qari.localFolder().appendingPathComponent(fileName).appendingPathExtension(Files.audioExtension)
    }
}
