//
//  GappedAudioPlayerInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
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

class GappedAudioPlayerInteractor: DefaultAudioPlayerInteractor {

    weak var delegate: AudioPlayerInteractorDelegate?

    let downloader: AudioFilesDownloader

    let lastAyahFinder: LastAyahFinder

    let player: AudioPlayer

    var downloadCancelled: Bool = false

    init(downloader: AudioFilesDownloader, lastAyahFinder: LastAyahFinder, player: AudioPlayer) {
        self.downloader = downloader
        self.lastAyahFinder = lastAyahFinder
        self.player = player
        self.player.delegate = self
    }
}
