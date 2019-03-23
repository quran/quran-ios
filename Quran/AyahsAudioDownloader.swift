//
//  AyahsAudioDownloader.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/21/17.
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

struct AyahsAudioDownloadRequest {
    let range: VerseRange
    let qari: Qari
}

struct AyahsAudioDownloader: Interactor {

    let downloader: DownloadManager
    let creator: AnyCreator<Qari, QariAudioFileListRetrieval>
    init(downloader: DownloadManager, creator: AnyCreator<Qari, QariAudioFileListRetrieval>) {
        self.downloader = downloader
        self.creator = creator
    }

    func execute(_ request: AyahsAudioDownloadRequest) -> Promise<DownloadBatchResponse> {
        return DispatchQueue.global().async(.promise) { () -> DownloadBatchRequest in
                let retriever = self.creator.create(request.qari)

                // get downloads
                let files = retriever
                    .get(for: request.qari, range: request.range)
                    .filter { !FileManager.documentsURL.appendingPathComponent($0.local).isReachable }
                    .map { DownloadRequest(url: $0.remote, resumePath: $0.local.resumePath, destinationPath: $0.local) }
                return DownloadBatchRequest(requests: files)
        }.then {
                // create downloads
                return self.downloader.download($0)
        }
    }
}
