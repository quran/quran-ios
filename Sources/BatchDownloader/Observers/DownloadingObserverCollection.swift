//
//  DownloadingObserverCollection.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/21/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Locking
import VLogging

public class DownloadingObserverCollection<Item: Hashable> {
    private var cancelling: Protected<Set<Item>> = Protected([])
    private var downloadingObservers: [Item: DownloadingObserver<Item>] = [:]
    public private(set) var items: [Item] = []
    public private(set) var responses: [Item: DownloadBatchResponse] = [:] {
        didSet {
            for (item, response) in responses {
                downloadingObservers[item] = DownloadingObserver(item: item, response: response, actions: observerActions)
            }
            itemsUpdated?(items)
        }
    }

    public var downloadProgress: ((Item, Int, Float) -> Void)?
    public var downloadCompleted: ((Item, Int) -> Void)?
    public var downloadFailed: ((Item, Int, Error) -> Void)?
    public var itemsUpdated: (([Item]) -> Void)?

    public init() {
    }

    private lazy var observerActions: DownloadingObserverActions<Item> = DownloadingObserverActions(
        onDownloadProgressUpdated: { [weak self] progress, item in
            self?.onDownloadProgressUpdated(progress: progress, for: item)
        },
        onDownloadFailed: { [weak self] error, item in
            self?.onDownloadFailed(withError: error, for: item)
        },
        onDownloadCompleted: { [weak self] item in
            self?.onDownloadCompleted(for: item)
        }
    )

    public func removeAll() {
        downloadingObservers.forEach { $1.stop() }
        items.removeAll()
        responses.removeAll()
    }

    public func observe(_ items: [Item], responses: [Item: DownloadBatchResponse]) {
        self.items = items
        self.responses = responses
    }

    public func startDownloading(item: Item, response: DownloadBatchResponse) {
        guard !cancelling.value.contains(item) else {
            logger.warning("Not starting download, but canceling it for \(item)")
            response.cancel()
            return
        }

        // update the item to be downloading
        responses[item] = response
    }

    public func stopDownloading(_ item: Item) {
        _ = cancelling.sync { $0.insert(item) }

        // remove old observer
        let observer = downloadingObservers.removeValue(forKey: item)
        observer?.cancel()

        // update the item to be not downloading
        responses[item] = nil
    }

    public func preparingDownloading(_ item: Item) {
        _ = cancelling.sync { $0.remove(item) }
    }
}

extension DownloadingObserverCollection {
    func onDownloadProgressUpdated(progress: Float, for item: Item) {
        guard let index = items.firstIndex(of: item) else {
            logger.warning("Cannot update progress for \(item). Item not found in local storage.")
            return
        }

        downloadProgress?(items[index], index, progress)
    }

    func onDownloadCompleted(for item: Item) {
        // remove old observer
        stopDownloading(item)

        guard let index = items.firstIndex(of: item) else {
            logger.warning("Cannot complete download for \(item). Item not found in local storage.")
            return
        }
        downloadCompleted?(items[index], index)
    }

    func onDownloadFailed(withError error: Error, for item: Item) {
        stopDownloading(item)

        guard let index = items.firstIndex(of: item) else {
            logger.warning("Cannot update failure for \(item). Item not found in local storage.")
            return
        }
        downloadFailed?(items[index], index, error)
    }
}
