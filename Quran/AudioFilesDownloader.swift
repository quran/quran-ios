//
//  AudioFilesDownloader.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/15/16.
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
import PromiseKit

class AudioFilesDownloader {

    let audioFileList: QariAudioFileListRetrieval
    let downloader: DownloadManager
    let ayahDownloader: AnyInteractor<AyahsAudioDownloadRequest, [DownloadNetworkResponse]>

    private var response: Response?

    init(audioFileList: QariAudioFileListRetrieval,
         downloader: DownloadManager,
         ayahDownloader: AnyInteractor<AyahsAudioDownloadRequest, [DownloadNetworkResponse]>) {
        self.audioFileList  = audioFileList
        self.downloader     = downloader
        self.ayahDownloader = ayahDownloader
    }

    func cancel() {
        response?.cancel()
        response = nil
    }

    func needsToDownloadFiles(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> Bool {
        let files = filesForQari(qari, startAyah: startAyah, endAyah: endAyah)
        return !files.filter { !FileManager.documentsURL.appendingPathComponent($0.destinationPath).isReachable }.isEmpty
    }

    func getCurrentDownloadResponse() -> Promise<Response?> {
        if let response = response {
            return Promise(value: response)
        } else {
            return downloader.getOnGoingDownloads().then { batches -> Response? in
                let downloads = batches.flatMap { $0.responses.filter { $0.download.isAudio } }
                self.createRequestWithDownloads(downloads)
                return self.response
            }
        }
    }

    func download(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> Promise<Response?> {
        return ayahDownloader
            .execute(AyahsAudioDownloadRequest(start: startAyah, end: endAyah, qari: qari))
            .then(on: .main) { responses -> Response? in
                // wrap the requests
                self.createRequestWithDownloads(responses)
                return self.response
        }
    }

    private func createRequestWithDownloads(_ downloads: [DownloadNetworkResponse]) {
        guard !downloads.isEmpty else { return }

        self.response = CollectionResponse(responses: downloads)
        self.response?.addCompletion { [weak self] _ in
            guard let `self` = self else {
                return
            }
            self.response = nil
        }
    }

    func filesForQari(_ qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [Download] {
        return audioFileList.get(for: qari, startAyah: startAyah, endAyah: endAyah).map {
            Download(url: $0.remote, resumePath: $0.local.stringByAppendingPath(Files.downloadResumeDataExtension), destinationPath: $0.local)
        }
    }
}
