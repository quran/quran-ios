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

    var request: Request? { set get }

    func filesForQari(_ qari: Qari,
                      startAyah: AyahNumber,
                      endAyah: AyahNumber) -> [(remoteURL: Foundation.URL, destination: String, resumeURL: String)]
}

extension DefaultAudioFilesDownloader {

    func cancel() {
        request?.cancel()
        request = nil
    }

    func resume() {
        request?.resume()
    }

    func suspend() {
        request?.suspend()
    }

    func needsToDownloadFiles(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> Bool {
        let files = filesForQari(qari, startAyah: startAyah, endAyah: endAyah)
        return !files.filter {
            if let result = try? (Files.DocumentsFolder.appendingPathComponent($0.destination) as Foundation.URL).checkResourceIsReachable() {
                return !result
            }
            return true
        }.isEmpty
    }

    func getCurrentDownloadRequest(_ completion: @escaping (Request?) -> Void) {
        if let request = request {
            completion(request)
        } else {
            downloader.getCurrentTasks { [weak self] (downloads) in
                self?.createRequestWithDownloads(downloads)
                completion(self?.request)
            }
        }
    }

    func download(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> Request? {
        // get all files
        let files = filesForQari(qari, startAyah: startAyah, endAyah: endAyah)
        var uniqueFiles = Set<Foundation.URL>()
        // filter out existing and duplicate files
        let filesToDownload = files.filter { (remoteURL, destination, _) in
            if !uniqueFiles.contains(remoteURL) {
                uniqueFiles.insert(remoteURL)
                if let result = try? (Files.DocumentsFolder.appendingPathComponent(destination) as Foundation.URL).checkResourceIsReachable() {
                    return !result
                }
                return true
            }
            return false
        }

        // create downloads
        let requests = downloader.download(filesToDownload.map { (
            method: .GET,
            url: $0.remoteURL,
            headers: nil,
            destination: $0.destination,
            resumeDestination: $0.resumeURL) })
        // wrap the requests
        self.createRequestWithDownloads(requests)
        return self.request
    }

    fileprivate func createRequestWithDownloads(_ downloads: [DownloadNetworkRequest]) {
        guard !downloads.isEmpty else { return }

        let progress = Progress(totalUnitCount: Int64(downloads.count))
        downloads.forEach { progress.addChildIOS8Compatible($0.progress, withPendingUnitCount: 1) }
        let request = AudioFilesDownloadRequest(requests: downloads, progress: progress)
        self.request = request

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
                    let request = self.request
                    self.request = nil
                    request?.cancel() // cancel other downloads
                    request?.onCompletion?(.failure(error))
                } else {
                    if allCompleted {
                        let request = self.request
                        self.request = nil
                        request?.onCompletion?(.success())
                    }
                }
            }
        }
    }
}
