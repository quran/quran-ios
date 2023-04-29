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
//  it under the terms of the GNU General License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General License for more details.
//

import Combine
import Foundation
import Locking

struct DownloadingObserverActions<Item> {
    let onDownloadProgressUpdated: (Float, Item) async -> Void
    let onDownloadFailed: (Error, Item) async -> Void
    let onDownloadCompleted: (Item) async -> Void
}

final class DownloadingObserver<Item>: NSObject {
    private let actions: DownloadingObserverActions<Item>

    private var progressCancellable: AnyCancellable?

    private let item: Item
    let response: DownloadBatchResponse

    private var stopped = Protected<Bool>(false)

    init(item: Item, response: DownloadBatchResponse, actions: DownloadingObserverActions<Item>) async {
        self.item = item
        self.response = response
        self.actions = actions
        super.init()
        await start()
    }

    func cancel() async {
        stop()
        await response.cancel()
    }

    func stop() {
        stopped.value = true
    }

    func start() async {
        stopped.value = false

        progressCancellable = response.progress.sink { [weak self] progress in
            Task { [self] in
                await self?.onProgressUpdated(to: progress.progress)
            }
        }
        response.promise.done(on: .main) { [weak self] _ in
            guard let self = self, !self.stopped.value else {
                return
            }
            Task {
                await self.actions.onDownloadCompleted(self.item)
            }
        }
        .catch(on: .main) { [weak self] error in
            guard let self = self, !self.stopped.value else {
                return
            }
            Task {
                await self.actions.onDownloadFailed(error, self.item)
            }
        }
    }

    private func onProgressUpdated(to progress: Double) async {
        guard !stopped.value else {
            return
        }
        await actions.onDownloadProgressUpdated(Float(progress), self.item)
    }
}
