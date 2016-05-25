//
//  AudioPlayer.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/16/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol AudioPlayerDelegate: class {

    func playingAyah(ayah: AyahNumber)

    func onPlaybackEnded()

    func onPlaybackPaused()
    func onPlaybackResumed()
}

protocol AudioPlayer {

    weak var delegate: AudioPlayerDelegate? { get set }

    func play(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber)

    func pause()

    func resume()

    func stop()

    func goForward()

    func goBackward()
}
