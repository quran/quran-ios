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

public final class DownloadManager: Sendable {
    typealias SessionFactory = (NetworkSessionDelegate, OperationQueue) -> NetworkSession
    private let session: NetworkSession
    private let handler: DownloadSessionDelegate
    private let dataController: DownloadBatchDataController

    public convenience init(
        maxSimultaneousDownloads: Int,
        configuration: URLSessionConfiguration,
        downloadsURL: URL
    ) async {
        await self.init(maxSimultaneousDownloads: maxSimultaneousDownloads,
                        sessionFactory: {
                            URLSession(configuration: configuration,
                                       delegate: NetworkSessionToURLSessionDelegate(networkSessionDelegate: $0),
                                       delegateQueue: $1)
                        },
                        persistence: GRDBDownloadsPersistence(fileURL: downloadsURL))
    }

    init(
        maxSimultaneousDownloads: Int,
        sessionFactory: @escaping SessionFactory,
        persistence: DownloadsPersistence
    ) async {
        let operationQueue = OperationQueue()
        operationQueue.name = "com.quran.downloads"
        operationQueue.maxConcurrentOperationCount = 1

        let dispatchQueue = DispatchQueue(label: "com.quran.downloads.dispatch")
        operationQueue.underlyingQueue = dispatchQueue

        let dataController = DownloadBatchDataController(maxSimultaneousDownloads: maxSimultaneousDownloads, persistence: persistence)
        do {
            try await attempt(times: 3) {
                try await dataController.loadBatchesFromPersistence()
            }
        } catch {
            crasher.recordError(error, reason: "Failed to retrieve initial download batches from persistence.")
        }

        self.dataController = dataController
        handler = DownloadSessionDelegate(dataController: dataController)
        session = sessionFactory(handler, operationQueue)

        await dataController.update(session: session)
        await populateRunningTasks()
    }

    @MainActor
    public func setBackgroundSessionCompletion(_ backgroundSessionCompletion: @MainActor @escaping () -> Void) {
        handler.setBackgroundSessionCompletion(backgroundSessionCompletion)
    }

    public func getOnGoingDownloads() async -> [DownloadBatchResponse] {
        await dataController.getOnGoingDownloads()
    }

    public func download(_ batch: DownloadBatchRequest) async throws -> DownloadBatchResponse {
        try await dataController.download(batch)
    }

    private func populateRunningTasks() async {
        let (_, _, downloadTasks) = await session.tasks()
        await dataController.setRunningTasks(downloadTasks)
    }
}
