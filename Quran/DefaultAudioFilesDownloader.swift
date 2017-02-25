//
//  DefaultAudioFilesDownloader.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/15/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

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
        return !files.filter {
            if let result = try? FileManager.default.documentsURL.appendingPathComponent($0.destinationPath).checkResourceIsReachable() {
                return !result
            }
            return true
        }.isEmpty
    }

    func getCurrentDownloadResponse() -> Response? {
        if let response = response {
            return response
        } else {
            let batches = downloader.getOnGoingDownloads()
            let downloads = batches.flatMap { $0 }
            createRequestWithDownloads(downloads)
            return response
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
                let destinationPath = FileManager.default.documentsURL.appendingPathComponent(downloadInfo.destinationPath)
                if let result = try? destinationPath.checkResourceIsReachable() {
                    return !result
                }
                return true
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
        downloads.forEach { progress.addChildIOS8Compatible($0.progress, withPendingUnitCount: 1) }
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
