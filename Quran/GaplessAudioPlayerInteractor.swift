//
//  GaplessAudioPlayerInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class GaplessAudioPlayerInteractor: DefaultAudioPlayerInteractor {

    weak var delegate: AudioPlayerInteractorDelegate? = nil

    let downloader: AudioFilesDownloader

    let player: AudioPlayer

    let lastAyahFinder: LastAyahFinder

    var downloadCancelled: Bool = false

    init(downloader: AudioFilesDownloader, lastAyahFinder: LastAyahFinder, player: AudioPlayer) {
        self.downloader = downloader
        self.lastAyahFinder = lastAyahFinder
        self.player = player
        self.player.delegate = self
    }
}
