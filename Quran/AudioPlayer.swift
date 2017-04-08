//
//  AudioPlayer.swift
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

protocol AudioPlayerDelegate: class {

    func playingAyah(_ ayah: AyahNumber)

    func onPlaybackEnded()

    func onPlaybackPaused()
    func onPlaybackResumed()
}

protocol AudioPlayer {

    weak var delegate: AudioPlayerDelegate? { get set }

    func play(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber)

    func pause()

    func resume()

    func stop()

    func goForward()

    func goBackward()
}
