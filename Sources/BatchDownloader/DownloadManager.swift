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
import PromiseKit
import Utilities

private let queue: OperationQueue = {
    let queue = OperationQueue()
    queue.name = "com.quran.downloads"
    queue.maxConcurrentOperationCount = 1
    return queue
}()

public final class DownloadManager {
    private(set) var session: URLSession! // swiftlint:disable:this implicitly_unwrapped_optional
    private var handler: ThreadSafeDownloadSessionDelegate?

    public var backgroundSessionCompletionHandler: (() -> Void)? {
        get { handler?.backgroundSessionCompletionHandler }
        set { handler?.backgroundSessionCompletionHandler = newValue }
    }

    private let initializationGroup = DispatchGroup()

    public convenience init(
        maxSimultaneousDownloads: Int,
        configuration: URLSessionConfiguration,
        downloadsPath: String
    ) {
        self.init(maxSimultaneousDownloads: maxSimultaneousDownloads,
                  configuration: configuration,
                  persistence: SqliteDownloadsPersistence(filePath: downloadsPath))
    }

    init(
        maxSimultaneousDownloads: Int,
        configuration: URLSessionConfiguration,
        persistence: DownloadsPersistence
    ) {
        initializationGroup.enter()

        let dataController = DownloadBatchDataController(maxSimultaneousDownloads: maxSimultaneousDownloads, persistence: persistence)
        queue.async(.promise) {
            try attempt(times: 3) {
                try dataController.loadBatchesFromPersistence()
            }
        }
        .ensure {
            // create handler classes
            let unsafeHandler = DownloadSessionDelegate(dataController: dataController)
            let handler = ThreadSafeDownloadSessionDelegate(unsafeHandler: unsafeHandler, queue: queue)
            unsafeHandler.cancellable = self.handler

            // create the session
            let session = URLSession(configuration: configuration, delegate: handler, delegateQueue: queue)

            // set the handler and session
            self.handler = handler
            self.session = session

            dataController.cancellable = handler
            dataController.session = session

            handler.populateRunningTasks(from: session)

            self.initializationGroup.leave()
        }
        .catch { error in
            crasher.recordError(error, reason: "Failed to retrieve initial download batches.")
        }
    }

    public func getOnGoingDownloads() -> Guarantee<[DownloadBatchResponse]> {
        initializationGroup
            .notify()
            .then { self.handler?.getOnGoingDownloads() ?? .value([]) }
    }

    public func download(_ batch: DownloadBatchRequest) -> Promise<DownloadBatchResponse> {
        initializationGroup
            .notify()
            .then { self.handler?.download(batch) ?? Promise.value(self.createFailureResponse()) }
    }

    private func createFailureResponse() -> DownloadBatchResponse {
        let response = DownloadBatchResponse(batchId: -1, responses: [], cancellable: nil)
        response.reject(NetworkError.unknown(nil))
        return response
    }
}

private extension DispatchGroup {
    func notify(on q: DispatchQueue = .global()) -> Guarantee<Void> {
        Guarantee { resolve in
            self.notify(queue: q) { resolve(()) }
        }
    }
}
