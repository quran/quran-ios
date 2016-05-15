//
//  GaplessAudioFilesDownloader.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class GaplessAudioFilesDownloader: DefaultAudioFilesDownloader {

    let downloader: NetworkManager

    var request: Request? = nil

    init(downloader: NetworkManager) {
        self.downloader = downloader
    }

    func filesForQari(qari: Qari,
                              startAyah: AyahNumber,
                              endAyah: AyahNumber) -> [(remoteURL: NSURL, destination: String, resumeURL: String)] {

        let databaseFileName: String
        switch qari.audioType {
        case .Gapless(let databaseName):
            databaseFileName = databaseName
        case .Gapped:
            fatalError("Unsupported qari type gapped. Only gapless qaris can be downloaded here.")
        }

        let databaseRemoteURL = URL.AudioDatabaseURL.URLByAppendingPathComponent(
            databaseFileName).URLByAppendingPathExtension(Files.DatabaseRemoteFileExtension)
        let databaseLocalURL = qari.path.stringByAppendingPath(
            databaseFileName).stringByAppendingExtension(Files.DatabaseRemoteFileExtension)
        let databaseResumeURL = databaseLocalURL.stringByAppendingExtension(Files.DownloadResumeDataExtension)

        // loop over the files
        var files = [(remoteURL: NSURL, destination: String, resumeURL: String)]()
        files.append(remoteURL: databaseRemoteURL, destination: databaseLocalURL, resumeURL: databaseResumeURL)

        for sura in startAyah.sura...endAyah.sura {
            let fileName = String(format: "%03d", sura)

            let remoteURL = qari.audioURL.URLByAppendingPathComponent(fileName).URLByAppendingPathExtension(Files.AudioExtension)
            let localURL = qari.path.stringByAppendingPath(fileName).stringByAppendingExtension(Files.AudioExtension)
            let resumeURL = localURL.stringByAppendingExtension(Files.DownloadResumeDataExtension)

            files.append(remoteURL: remoteURL, destination: localURL, resumeURL: resumeURL)
        }
        return files
    }
}
