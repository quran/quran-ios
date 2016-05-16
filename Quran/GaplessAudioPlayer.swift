//
//  GaplessAudioPlayer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/16/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import AVFoundation

class GaplessAudioPlayer: NSObject, DefaultAudioPlayer {

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
        return filesToPlay(qari: qari, startAyah: startAyah, endAyah: endAyah).map { AVPlayerItem(URL: $0) }
    }

    private func filesToPlay(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [NSURL] {

        guard case AudioType.Gapless = qari.audioType else {
            fatalError("Unsupported qari type gapped. Only gapless qaris can be played here.")
        }

        // loop over the files
        var files = [NSURL]()

        for sura in startAyah.sura...endAyah.sura {
            let fileName = String(format: "%03d", sura)
            let localURL = qari.localFolder().URLByAppendingPathComponent(fileName).URLByAppendingPathExtension(Files.AudioExtension)
            files.append(localURL)
        }
        return files
    }

    func goForward() {
        // not implemented
    }

    func goBackward() {
        // not implemented
    }

    func onPlayerItemChangedTo(newItem: AVPlayerItem) {

    }
}
