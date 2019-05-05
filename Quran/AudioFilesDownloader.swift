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
import BatchDownloader
import PromiseKit

class AudioFilesDownloader {

    private let gapplessAudioFileList: QariAudioFileListRetrieval
    private let gappedAudioFileList: QariAudioFileListRetrieval

    private let downloader: DownloadManager
    private let ayahDownloader: AyahsAudioDownloaderType

    private var response: DownloadBatchResponse?

    init(gapplessAudioFileList: QariAudioFileListRetrieval,
         gappedAudioFileList: QariAudioFileListRetrieval,
         downloader: DownloadManager,
         ayahDownloader: AyahsAudioDownloaderType) {
        self.gapplessAudioFileList = gapplessAudioFileList
        self.gappedAudioFileList = gappedAudioFileList
        self.downloader = downloader
        self.ayahDownloader = ayahDownloader
    }

    func cancel() {
        response?.cancel()
        response = nil
    }

    func needsToDownloadFiles(qari: Qari, range: VerseRange) -> Bool {
        let files = filesForQari(qari, range: range)
        return !files.filter { !FileManager.documentsURL.appendingPathComponent($0.destinationPath).isReachable }.isEmpty
    }

    func getCurrentDownloadResponse() -> Guarantee<DownloadBatchResponse?> {
        if let response = response {
            return Guarantee.value(response)
        } else {
            return downloader.getOnGoingDownloads().map { batches -> DownloadBatchResponse? in
                let downloading = batches.first { $0.isAudio }
                self.createRequestWithDownloads(downloading)
                return self.response
            }
        }
    }

    func download(qari: Qari, range: VerseRange) -> Promise<DownloadBatchResponse?> {
        return ayahDownloader
            .download(AyahsAudioDownloadRequest(range: range, qari: qari))
            .map(on: .main) { responses -> DownloadBatchResponse? in
                // wrap the requests
                self.createRequestWithDownloads(responses)
                return self.response
            }
    }

    private func createRequestWithDownloads(_ batch: DownloadBatchResponse?) {
        guard let batch = batch else { return }

        response = batch
        response?.promise.ensure { [weak self] in
            self?.response = nil
        }.cauterize(tag: "AudioFilesDownloader.createRequestWithDownloads")
    }

    func filesForQari(_ qari: Qari, range: VerseRange) -> [DownloadRequest] {
        let audioFileList = getAudioFileList(for: qari)
        return audioFileList.get(for: qari, range: range).map {
            DownloadRequest(url: $0.remote, resumePath: $0.local.stringByAppendingPath(Files.downloadResumeDataExtension), destinationPath: $0.local)
        }
    }

    private func getAudioFileList(for qari: Qari) -> QariAudioFileListRetrieval {
        switch qari.audioType {
        case .gapless: return gapplessAudioFileList
        case .gapped: return gappedAudioFileList
        }
    }
}
