//
//  GappedAudioPlayer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/16/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import AVFoundation

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

class GappedAudioPlayer: NSObject, DefaultAudioPlayer {

    weak var delegate: AudioPlayerDelegate?

    var inAudioSession: Bool = false

    let player = AVQueuePlayer()

    var playingItems: [AVPlayerItem] = []

    var observingObject: NSObject {
        return self
    }

    override init() {
        super.init()
        let _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord,
                                                                 withOptions: [.DefaultToSpeaker, .AllowBluetooth])
        player.actionAtItemEnd = .Advance
    }

    func playerItemsForQari(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [AVPlayerItem] {
        return filesToPlay(qari: qari, startAyah: startAyah, endAyah: endAyah).map { GappedPlayerItem(URL: $0, ayah: $1) }
    }

    func goForward() {
        playNextAudio(starting: 0)
    }

    func goBackward() {
        playPreviousAudio(starting: 0)
    }

    func onPlayerItemChangedTo(newItem: AVPlayerItem) {
        if let newItem = newItem as? GappedPlayerItem {
            delegate?.playingAyah(newItem.ayah)
        }
    }
}

extension GappedAudioPlayer {

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
