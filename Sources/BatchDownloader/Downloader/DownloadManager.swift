//
//  URLSessionDownloadManager.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
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

import Crashing
import Foundation
import Utilities

public final class DownloadManager {
    typealias SessionFactory = (NetworkSessionDelegate, OperationQueue) -> NetworkSession
    private let session: NetworkSession
    private let handler: DownloadSessionDelegate

    let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.quran.downloads"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    let dispatchQueue = DispatchQueue(label: "com.quran.downloads.dispatch")

    public convenience init(
        maxSimultaneousDownloads: Int,
        configuration: URLSessionConfiguration,
        downloadsPath: String
    ) async {
        await self.init(maxSimultaneousDownloads: maxSimultaneousDownloads,
                  sessionFactory: {
                      URLSession(configuration: configuration,
                                 delegate: NetworkSessionToURLSessionDelegate(networkSessionDelegate: $0),
                                 delegateQueue: $1)
                  },
                  persistence: SqliteDownloadsPersistence(filePath: downloadsPath))
    }

    init(
        maxSimultaneousDownloads: Int,
        sessionFactory: @escaping SessionFactory,
        persistence: DownloadsPersistence
    ) async {
        operationQueue.underlyingQueue = dispatchQueue

        let dataController = DownloadBatchDataController(maxSimultaneousDownloads: maxSimultaneousDownloads, persistence: persistence)
        do {
            try await attempt(times: 3) {
                try await dataController.loadBatchesFromPersistence()
            }
        } catch {
            crasher.recordError(error, reason: "Failed to retrieve initial download batches from persistence.")
        }

        do {
            handler = DownloadSessionDelegate(dataController: dataController)
            session = sessionFactory(handler, operationQueue)

            await dataController.update(session: session)
            try await handler.populateRunningTasks(from: session)
        } catch {
            crasher.recordError(error, reason: "Failed to retrieve download tasks.")
        }
    }

    @MainActor
    public func setBackgroundSessionCompletion(_ backgroundSessionCompletion: (() -> Void)?) {
        handler.setBackgroundSessionCompletion(backgroundSessionCompletion)
    }

    public func getOnGoingDownloads() async -> [DownloadBatchResponse] {
        await handler.getOnGoingDownloads()
    }

    public func download(_ batch: DownloadBatchRequest) async throws -> DownloadBatchResponse {
        try await handler.download(batch)
    }
}
