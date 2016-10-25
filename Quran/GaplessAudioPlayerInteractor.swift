//
//  GaplessAudioPlayerInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import Zip

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

    func prePlayOperation(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber, completion: @escaping () -> Void) {
        guard case .gapless(let databaseName) = qari.audioType else {
            fatalError("Unsupported qari type gapped")
        }
        let baseFileName = qari.localFolder().appendingPathComponent(databaseName)
        let dbFile = baseFileName.appendingPathExtension(Files.DatabaseLocalFileExtension)
        let zipFile = baseFileName.appendingPathExtension(Files.DatabaseRemoteFileExtension)

        do {
            guard try !(dbFile as Foundation.URL).checkResourceIsReachable() else {
                completion()
                return
            }
        } catch _ {
            completion()
            return
        }

        Queue.background.async {
            do {
                try Zip.unzipFile(zipFile, destination: qari.localFolder(), overwrite: true, password: nil, progress: nil)
            } catch {
                Crash.recordError(error)
                // delete the zip and try to re-download it again, next time.
                let _ = try? FileManager.default.removeItem(at: zipFile)
            }

            Queue.main.async {
                completion()
            }
        }
    }
}
