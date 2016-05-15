//
//  DefaultAudioFilesDownloader.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/15/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol DefaultAudioFilesDownloader: AudioFilesDownloader {

    var downloader: NetworkManager { get }

    var request: Request? { set get }

    func filesForQari(qari: Qari,
                      startAyah: AyahNumber,
                      endAyah: AyahNumber) -> [(remoteURL: NSURL, destination: String, resumeURL: String)]
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

    func needsToDownloadFiles(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> Bool {
        let files = filesForQari(qari, startAyah: startAyah, endAyah: endAyah)
        return !files.filter { !Files.DocumentsFolder.URLByAppendingPathComponent(
            $0.destination).checkResourceIsReachableAndReturnError(nil) }.isEmpty
    }

    func getCurrentDownloadRequest(completion: Request? -> Void) {
        if let request = request {
            completion(request)
        } else {
            downloader.getCurrentTasks { [weak self] (downloads) in
                self?.createRequestWithDownloads(downloads)
                completion(self?.request)
            }
        }
    }

    func download(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> Request? {
        // get all files
        let files = filesForQari(qari, startAyah: startAyah, endAyah: endAyah)
        // filter out existing files
        let filesToDownload = files.filter { !Files.DocumentsFolder.URLByAppendingPathComponent(
            $0.destination).checkResourceIsReachableAndReturnError(nil) }
        print("Will download files: \(filesToDownload.map { ($0.remoteURL, $0.destination) })")

        // create downloads
        let requests = filesToDownload.map {
            return downloader.download(.GET, url: $0.remoteURL, destination: $0.destination, resumeDestination: $0.resumeURL)
        }
        // wrap the requests
        self.createRequestWithDownloads(requests)
        return self.request
    }

    private func createRequestWithDownloads(downloads: [Request]) {
        guard !downloads.isEmpty else { return }

        let progress = Progress(totalUnitCount: Int64(downloads.count))
        downloads.forEach { progress.addChildIOS8Compatible($0.progress, withPendingUnitCount: 1) }
        let request = AudioFilesDownloadRequest(requests: downloads, progress: progress)
        self.request = request

        var completed = 0
        let total = downloads.count
        for download in downloads {
            download.onCompletion = { [weak self] result in
                completed += 1

                // if error occurred, stop downloads
                if let error = result.error {
                    let request = self?.request
                    self?.request = nil
                    request?.cancel() // cancel other downloads
                    request?.onCompletion?(.Failure(error))
                } else {
                    if completed == total {
                        let request = self?.request
                        self?.request = nil
                        request?.onCompletion?(.Success())
                    }
                }
            }
        }
    }
}
