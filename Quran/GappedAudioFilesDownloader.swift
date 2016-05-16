//
//  GappedAudioFilesDownloader.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class GappedAudioFilesDownloader: DefaultAudioFilesDownloader {

    let downloader: NetworkManager

    var request: Request? = nil

    init(downloader: NetworkManager) {
        self.downloader = downloader
    }

    func filesForQari(qari: Qari,
                      startAyah: AyahNumber,
                      endAyah: AyahNumber) -> [(remoteURL: NSURL, destination: String, resumeURL: String)] {

        var files = [(remoteURL: NSURL, destination: String, resumeURL: String)]()
        for sura in startAyah.sura...endAyah.sura {

            let startAyahNumber = sura == startAyah.sura ? startAyah.ayah : 1
            let endAyahNumber = sura == endAyah.sura ? endAyah.ayah : Quran.numberOfAyahsForSura(sura)

            for ayah in startAyahNumber...endAyahNumber {
                files.append(createRequestInfo(qari: qari, sura: sura, ayah: ayah))
            }
        }

        // add besm Allah
        if startAyah.sura != 1 || startAyah.ayah == 1 {
            files.append(createRequestInfo(qari: qari, sura: 1, ayah: 1))
        }

        return files
    }

    private func createRequestInfo(qari qari: Qari, sura: Int, ayah: Int) -> (remoteURL: NSURL, destination: String, resumeURL: String) {
        let fileName = String(format: "%03d%03d", sura, ayah)
        let remoteURL = qari.audioURL.URLByAppendingPathComponent(fileName).URLByAppendingPathExtension(Files.AudioExtension)
        let localURL = qari.path.stringByAppendingPath(fileName).stringByAppendingExtension(Files.AudioExtension)
        let resumeURL = localURL.stringByAppendingExtension(Files.DownloadResumeDataExtension)
        return (remoteURL: remoteURL, destination: localURL, resumeURL: resumeURL)
    }
}
