//
//  DownloadManager.swift
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

import Foundation
import NetworkSupport
import SystemDependencies
import VLogging

public final class DownloadManager: Sendable {
    typealias SessionFactory = @Sendable (NetworkSessionDelegate, OperationQueue) -> NetworkSession

    // MARK: Lifecycle

    public convenience init(
        maxSimultaneousDownloads: Int,
        configuration: URLSessionConfiguration,
        downloadsURL: URL
    ) {
        self.init(
            maxSimultaneousDownloads: maxSimultaneousDownloads,
            sessionFactory: {
                URLSession(
                    configuration: configuration,
                    delegate: NetworkSessionToURLSessionDelegate(networkSessionDelegate: $0),
                    delegateQueue: $1
                )
            },
            persistence: GRDBDownloadsPersistence(fileURL: downloadsURL)
        )
    }

    init(
        maxSimultaneousDownloads: Int,
        sessionFactory: @escaping SessionFactory,
        persistence: DownloadsPersistence,
        fileManager: FileSystem = DefaultFileSystem()
    ) {
        let dataController = DownloadBatchDataController(
            maxSimultaneousDownloads: maxSimultaneousDownloads,
            persistence: persistence
        )
        self.dataController = dataController
        self.sessionFactory = sessionFactory
        handler = DownloadSessionDelegate(dataController: dataController, fileManager: fileManager)
    }

    // MARK: Public

    public func start() async {
        logger.info("Starting download manager")
        let session = createSession()
        await dataController.start(with: session)
        logger.info("Download manager started")
    }

    @MainActor
    public func setBackgroundSessionCompletion(_ backgroundSessionCompletion: @MainActor @escaping () -> Void) {
        handler.setBackgroundSessionCompletion(backgroundSessionCompletion)
    }

    public func getOnGoingDownloads() async -> [DownloadBatchResponse] {
        logger.info("getOnGoingDownloads requested")
        let downloads = await dataController.getOnGoingDownloads()
        logger.debug("Found \(downloads.count) ongoing downloads")
        return downloads
    }

    public func download(_ batch: DownloadBatchRequest) async throws -> DownloadBatchResponse {
        logger.debug("Requested to download \(batch.requests.map(\.url.absoluteString))")
        let result = try await dataController.download(batch)
        return result
    }

    public func cancel(downloads: [DownloadBatchResponse]) async {
        guard !downloads.isEmpty else {
            return
        }

        await withTaskGroup(of: Void.self) { group in
            for download in downloads {
                group.addTask {
                    await download.cancel()
                    await Self.waitForCompletion(of: download)
                }
            }
        }

        let batchIds = Set(downloads.map(\.batchId))
        await dataController.waitUntilBatchesRemoved(batchIds: batchIds)
    }

    // MARK: Private

    private let sessionFactory: SessionFactory
    private nonisolated(unsafe) var session: NetworkSession?
    private let handler: DownloadSessionDelegate
    private let dataController: DownloadBatchDataController

    private static func waitForCompletion(of download: DownloadBatchResponse) async {
        do {
            for try await _ in download.progress { }
        } catch { }
    }

    private func createSession() -> NetworkSession {
        let operationQueue = OperationQueue()
        operationQueue.name = "com.quran.downloads"
        operationQueue.maxConcurrentOperationCount = 1

        let dispatchQueue = DispatchQueue(label: "com.quran.downloads.dispatch")
        operationQueue.underlyingQueue = dispatchQueue

        let session = sessionFactory(handler, operationQueue)
        self.session = session

        return session
    }
}
