//
//  DefaultAudioFilesDownloader.swift
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

protocol DefaultAudioFilesDownloader: AudioFilesDownloader {

    var downloader: DownloadManager { get }

    var response: Response? { set get }

    func filesForQari(_ qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [Download]
}

extension DefaultAudioFilesDownloader {

    func cancel() {
        response?.cancel()
        response = nil
    }

    func resume() {
        response?.resume()
    }

    func suspend() {
        response?.suspend()
    }

    func needsToDownloadFiles(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> Bool {
        let files = filesForQari(qari, startAyah: startAyah, endAyah: endAyah)
        return !files.filter { !FileManager.default.documentsURL.appendingPathComponent($0.destinationPath).isReachable }.isEmpty
    }

    func getCurrentDownloadResponse() -> Promise<Response?> {
        if let response = response {
            return Promise(value: response)
        } else {
            return downloader.getOnGoingDownloads().then { batches -> Response? in
                let downloads = batches.flatMap { $0.filter { $0.download.isAudio } }
                self.createRequestWithDownloads(downloads)
                return self.response
            }
        }
    }

    func download(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> Response? {
        // get all files
        let files = filesForQari(qari, startAyah: startAyah, endAyah: endAyah)
        var uniqueFiles = Set<URL>()
        // filter out existing and duplicate files
        let filesToDownload = files.filter { downloadInfo in
            if !uniqueFiles.contains(downloadInfo.url) {
                uniqueFiles.insert(downloadInfo.url)
                let destinationURL = FileManager.default.documentsURL.appendingPathComponent(downloadInfo.destinationPath)
                return !destinationURL.isReachable
            }
            return false
        }

        // create downloads
        let requests = downloader.download(filesToDownload.map { DownloadRequest( method: .GET, download: $0) })
        // wrap the requests
        self.createRequestWithDownloads(requests)
        return self.response
    }

    fileprivate func createRequestWithDownloads(_ downloads: [DownloadNetworkResponse]) {
        guard !downloads.isEmpty else { return }

        let progress = Progress(totalUnitCount: Int64(downloads.count))

        downloads.forEach { progress.addChild($0.progress, withPendingUnitCount: 1) }
        let response = AudioFilesDownloadResponse(responses: downloads, progress: progress)
        self.response = response

        let completionLock = NSLock()

        var completed = 0
        let total = downloads.count
        for download in downloads {
            download.onCompletion = { [weak self] result in
                guard let `self` = self else {
                    return
                }

                let allCompleted: Bool = completionLock.execute {
                    completed += 1
                    return completed == total
                }

                // if error occurred, stop downloads
                if let error = result.error {
                    let response = self.response
                    Queue.main.after(0.2) {
                        self.response = nil
                    }
                    response?.cancel() // cancel other downloads
                    response?.result = .failure(error)
                } else {
                    if allCompleted {
                        let response = self.response
                        self.response = nil
                        response?.result = .success()
                    }
                }
            }
        }
    }
}
