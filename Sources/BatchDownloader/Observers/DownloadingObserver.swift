//
//  DownloadingObserver.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/17.
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
import Locking

public struct DownloadingObserverActions<Item> {
    public init(
        onDownloadProgressUpdated: @escaping (Float, Item) -> Void,
        onDownloadFailed: @escaping (Error, Item) -> Void,
        onDownloadCompleted: @escaping (Item) -> Void
    ) {
        self.onDownloadProgressUpdated = onDownloadProgressUpdated
        self.onDownloadFailed = onDownloadFailed
        self.onDownloadCompleted = onDownloadCompleted
    }

    let onDownloadProgressUpdated: (Float, Item) -> Void
    let onDownloadFailed: (Error, Item) -> Void
    let onDownloadCompleted: (Item) -> Void
}

public final class DownloadingObserver<Item>: NSObject, QProgressListener {
    private let actions: DownloadingObserverActions<Item>

    private let item: Item
    public let response: DownloadBatchResponse

    private var stopped = Protected<Bool>(false)

    public init(item: Item, response: DownloadBatchResponse, actions: DownloadingObserverActions<Item>) {
        self.item = item
        self.response = response
        self.actions = actions
        super.init()
        start()
    }

    public func cancel() {
        stop()
        response.cancel()
    }

    public func stop() {
        stopped.value = true
    }

    func start() {
        stopped.value = false

        response.progress.progressListeners.insert(self)
        response.promise.done(on: .main) { [weak self] _ in
            guard let self = self, !self.stopped.value else {
                return
            }
            self.actions.onDownloadCompleted(self.item)
        }
        .catch(on: .main) { [weak self] error in
            guard let self = self, !self.stopped.value else {
                return
            }
            self.actions.onDownloadFailed(error, self.item)
        }
        onProgressUpdated(to: response.progress.progress)
    }

    public func onProgressUpdated(to progress: Double) {
        DispatchQueue.main.async {
            guard !self.stopped.value else {
                return
            }
            self.actions.onDownloadProgressUpdated(Float(progress), self.item)
        }
    }
}
