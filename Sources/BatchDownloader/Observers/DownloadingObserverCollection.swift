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
    public private(set) var responses: [Item: DownloadBatchResponse] = [:]

    public var downloadProgress: ((Item, Int, Float) async -> Void)?
    public var downloadCompleted: ((Item, Int) async -> Void)?
    public var downloadFailed: ((Item, Int, Error) async -> Void)?
    public var itemsUpdated: (([Item]) async -> Void)?

    public init() {
    }

    private lazy var observerActions: DownloadingObserverActions<Item> = DownloadingObserverActions(
        onDownloadProgressUpdated: { [weak self] progress, item in
            await self?.onDownloadProgressUpdated(progress: progress, for: item)
        },
        onDownloadFailed: { [weak self] error, item in
            await self?.onDownloadFailed(withError: error, for: item)
        },
        onDownloadCompleted: { [weak self] item in
            await self?.onDownloadCompleted(for: item)
        }
    )

    private func updateResponses(_ body: (inout [Item: DownloadBatchResponse]) -> Void) async {
        body(&responses)

        for (item, response) in responses {
            downloadingObservers[item] = await DownloadingObserver(item: item, response: response, actions: observerActions)
        }
        await itemsUpdated?(items)
    }

    public func removeAll() async {
        downloadingObservers.forEach { $1.stop() }
        items.removeAll()
        await updateResponses { $0.removeAll() }
    }

    public func observe(_ items: [Item], responses: [Item: DownloadBatchResponse]) async {
        self.items = items
        await updateResponses { $0 = responses }
    }

    public func startDownloading(item: Item, response: DownloadBatchResponse) async {
        guard !cancelling.value.contains(item) else {
            logger.warning("Not starting download, but canceling it for \(item)")
            await response.cancel()
            return
        }

        // update the item to be downloading
        await updateResponses { $0[item] = response }
    }

    public func stopDownloading(_ item: Item) async {
        _ = cancelling.sync { $0.insert(item) }

        // remove old observer
        let observer = downloadingObservers.removeValue(forKey: item)
        await observer?.cancel()

        // update the item to be not downloading
        await updateResponses { $0[item] = nil }
    }

    public func preparingDownloading(_ item: Item) {
        _ = cancelling.sync { $0.remove(item) }
    }
}

extension DownloadingObserverCollection {
    func onDownloadProgressUpdated(progress: Float, for item: Item) async {
        guard let index = items.firstIndex(of: item) else {
            logger.warning("Cannot update progress for \(item). Item not found in local storage.")
            return
        }

        await downloadProgress?(items[index], index, progress)
    }

    func onDownloadCompleted(for item: Item) async {
        // remove old observer
        await stopDownloading(item)

        guard let index = items.firstIndex(of: item) else {
            logger.warning("Cannot complete download for \(item). Item not found in local storage.")
            return
        }
        await downloadCompleted?(items[index], index)
    }

    func onDownloadFailed(withError error: Error, for item: Item) async {
        await stopDownloading(item)

        guard let index = items.firstIndex(of: item) else {
            logger.warning("Cannot update failure for \(item). Item not found in local storage.")
            return
        }
        await downloadFailed?(items[index], index, error)
    }
}
