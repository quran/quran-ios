//
//  DownloadObserversRecorder.swift
//
//
//  Created by Mohamed Afifi on 2022-02-05.
//

@testable import BatchDownloader
import Foundation
import Locking

class DownloadObserversRecorder<Item: Hashable>: NetworkResponseCancellable {
    enum Record<Item: Hashable>: Hashable {
        case progress(Item, Int, Float)
        case completed(Item, Int)
        case failed(Item, Int, NSError)
        case itemsUpdated([Item])
        case cancel(response: DownloadBatchResponse)
    }

    private var records: Protected<[Record<Item>]> = Protected([])

    init(observer: DownloadingObserverCollection<Item>) {
        observer.downloadProgress = { x, y, z in
            self.records.sync { $0.append(.progress(x, y, z)) }
        }
        observer.downloadCompleted = { x, y in
            self.records.sync { $0.append(.completed(x, y)) }
        }
        observer.downloadFailed = { x, y, z in
            self.records.sync { $0.append(.failed(x, y, z as NSError)) }
        }
        observer.itemsUpdated = { [weak observer] x in
            self.records.sync { $0.append(.itemsUpdated(x)) }
            for response in (observer?.responses.values.map { $0 } ?? []) {
                response.cancellable = self
            }
        }
    }

    var diffSinceLastCalled: [Record<Item>] {
        records.sync { value in
            let lastValue = value
            // clear the value
            value = []
            return lastValue
        }
    }

    func cancel(batch: DownloadBatchResponse) {
        records.sync { $0.append(.cancel(response: batch)) }
    }
}

extension DownloadBatchResponse: Hashable {
    public static func == (lhs: DownloadBatchResponse, rhs: DownloadBatchResponse) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
