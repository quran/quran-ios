//
//  GappedAudioPlayer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/16/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import MediaPlayer

private class GappedPlayerItem: AVPlayerItem {
    let ayah: AyahNumber
    init(URL: NSURL, ayah: AyahNumber) {
        self.ayah = ayah
        super.init(asset: AVAsset(URL: URL), automaticallyLoadedAssetKeys: nil)
    }

    private override var description: String {
        return super.description + " ayah: \(ayah)"
    }
}

class GappedAudioPlayer: DefaultAudioPlayer {

    let numberFormatter = NSNumberFormatter()

    weak var delegate: AudioPlayerDelegate?

    let player = QueuePlayer()

    func play(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) {
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

    private func playerItemsForQari(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> ([GappedPlayerItem], [PlayerItemInfo]) {
        let files = filesToPlay(qari: qari, startAyah: startAyah, endAyah: endAyah)
        let items = files.map { GappedPlayerItem(URL: $0, ayah: $1) }
        let info: [PlayerItemInfo] = files.map { (url, ayah) in
            let descriptionFormat = NSLocalizedString("suraNameAndAyahNumber", comment: "")
            let suraName = NSLocalizedString("sura_names[\(ayah.sura - 1)]", comment: "")
            let title = String(format: descriptionFormat, suraName, numberFormatter.format(ayah.ayah))

            return PlayerItemInfo(
                title: title,
                artist: qari.name,
                artwork: qari.imageName.flatMap({UIImage(named: $0)}).flatMap { MPMediaItemArtwork(image: $0) })
        }
        return (items, info)
    }

    private func filesToPlay(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [(NSURL, AyahNumber)] {

        guard case AudioType.Gapped = qari.audioType else {
            fatalError("Unsupported qari type gapless. Only gapless qaris can be downloaded here.")
        }

        var files = [(NSURL, AyahNumber)]()

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

    private func createRequestInfo(qari qari: Qari, sura: Int, ayah: Int) -> NSURL {
        let fileName = String(format: "%03d%03d", sura, ayah)
        let url = qari.localFolder().URLByAppendingPathComponent(fileName).URLByAppendingPathExtension(Files.AudioExtension)
        return url
    }
}
