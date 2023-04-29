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
import Crashing
import Foundation
import PromiseKit
import QuranKit

class AudioFilesDownloader {
    private let fileListFactory: ReciterAudioFileListRetrievalFactory

    private let downloader: DownloadManager
    private let ayahDownloader: AyahsAudioDownloader
    private let fileSystem: FileSystem

    private var response: DownloadBatchResponse?

    init(fileListFactory: ReciterAudioFileListRetrievalFactory,
         downloader: DownloadManager,
         ayahDownloader: AyahsAudioDownloader,
         fileSystem: FileSystem)
    {
        self.fileListFactory = fileListFactory
        self.downloader = downloader
        self.ayahDownloader = ayahDownloader
        self.fileSystem = fileSystem
    }

    func cancel() {
        Task {
            await response?.cancel()
            response = nil
        }
    }

    func needsToDownloadFiles(reciter: Reciter, from start: AyahNumber, to end: AyahNumber) -> Bool {
        let files = filesForReciter(reciter, from: start, to: end)
        return files.contains { !fileSystem.fileExists(at: FileManager.documentsURL.appendingPathComponent($0.destinationPath)) }
    }

    func getCurrentDownloadResponse() -> Guarantee<DownloadBatchResponse?> {
        DispatchQueue.global().asyncGuarantee {
            if let response = self.response {
                return response
            } else {
                let batches = await self.downloader.getOnGoingDownloads()
                let downloading = batches.first { $0.isAudio }
                self.createRequestWithDownloads(downloading)
                return self.response
            }
        }
    }

    func download(reciter: Reciter, from start: AyahNumber, to end: AyahNumber) -> Promise<DownloadBatchResponse?> {
        ayahDownloader
            .download(from: start, to: end, reciter: reciter)
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
        }
        .catch { error in
            crasher.recordError(error, reason: "Audio Download Promise failed.")
        }
    }

    private func filesForReciter(_ reciter: Reciter, from start: AyahNumber, to end: AyahNumber) -> [DownloadRequest] {
        let audioFileList = getAudioFileList(for: reciter)
        return audioFileList.get(for: reciter, from: start, to: end).map {
            DownloadRequest(url: $0.remote, destinationPath: $0.local)
        }
    }

    private func getAudioFileList(for reciter: Reciter) -> ReciterAudioFileListRetrieval {
        fileListFactory.fileListRetrievalForReciter(reciter)
    }
}
